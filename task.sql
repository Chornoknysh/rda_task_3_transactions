-- 1. Повне пересоздання схеми та завантаження DDL
DROP DATABASE IF EXISTS ShopDB;
CREATE DATABASE ShopDB;

-- Якщо в одному файлі не працює SOURCE, перед виконанням цього скрипта:
--   SOURCE create-database.sql;
USE ShopDB;

-- 2. Гарантований «seed» записів для FK (Requirement 2.4/3.5)
INSERT IGNORE INTO Customers
  (ID, FirstName, LastName, Email, Address)
VALUES
  (1, 'Test', 'Customer', 'test@example.com', '123 Test Street');

INSERT IGNORE INTO Products
  (ID, Name, Description, Price, WarehouseAmount)
VALUES
  (1, 'AwersomeProduct', 'The only product we have', 100, 100);

-- 3. Процедура з транзакцією, обробкою помилок та блокуванням рядка
DELIMITER $$
CREATE PROCEDURE CreateOrderWithItem()
BEGIN
  -- Гарантований ROLLBACK у разі будь-якої SQL-помилки
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
  END;

  START TRANSACTION;

  -- 3.1 Блокуємо рядок продукту для уникнення одновременної «продажі в нуль»
  SELECT WarehouseAmount
    INTO @current_stock
    FROM Products
    WHERE ID = 1
    FOR UPDATE;

  -- 3.2 Перевіряємо запас
  IF @current_stock < 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Insufficient stock for product ID=1';
  END IF;

  -- 3.3 Створюємо нове замовлення
  INSERT INTO Orders (CustomerID, Date)
    VALUES (1, '2023-01-01');
  SET @new_order_id = LAST_INSERT_ID();

  -- 3.4 Додаємо пункт до замовлення
  INSERT INTO OrderItems (OrderID, ProductID, Count)
    VALUES (@new_order_id, 1, 1);

  -- 3.5 Оновлюємо залишок на складі
  UPDATE Products
    SET WarehouseAmount = WarehouseAmount - 1
    WHERE ID = 1;

  COMMIT;
END$$
DELIMITER ;

-- 4. Викликаємо процедуру (за потреби можна викликати кілька разів)
CALL CreateOrderWithItem();
