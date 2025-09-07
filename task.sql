-- 1. Пересоздаємо базу і завантажуємо схему
DROP DATABASE IF EXISTS ShopDB;
CREATE DATABASE ShopDB;

-- Якщо MySQL не підтримує в середині скрипту SOURCE, то перед виконанням
-- цього файлу в клієнті запустіть:
--   SOURCE create-database.sql;
USE ShopDB;

-- 2. Створюємо процедуру з транзакцією та обробником помилок
DELIMITER $$
CREATE PROCEDURE CreateOrderWithItem()
BEGIN
  -- У випадку будь-якої помилки автоматично відкочується транзакція
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
  END;

  START TRANSACTION;

  -- 2.1 Створюємо нове порожнє замовлення (клієнт ID=1, довільна дата)
  INSERT INTO Orders (CustomerID, Date)
    VALUES (1, '2023-01-01');
  SET @new_order_id = LAST_INSERT_ID();

  -- 2.2 Перевіряємо наявність товару на складі (щоб не сталося негативного залишку)
  SELECT WarehouseAmount
    INTO @current_stock
    FROM Products
    WHERE ID = 1;

  IF @current_stock < 1 THEN
    -- Якщо немає в наявності — вилучення транзакції та стоп
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Insufficient stock for product ID=1';
  END IF;

  -- 2.3 Додаємо позицію в замовлення і зменшуємо складський залишок
  INSERT INTO OrderItems (OrderID, ProductID, Count)
    VALUES (@new_order_id, 1, 1);
  UPDATE Products
    SET WarehouseAmount = WarehouseAmount - 1
    WHERE ID = 1;

  COMMIT;
END$$
DELIMITER ;

-- 3. Викликаємо нашу процедуру
CALL CreateOrderWithItem();
