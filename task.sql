-- Use our database
USE ShopDB; 

-- Some data should be created outside the transaction (here)

-- Start the transaction 
START TRANSACTION; 

INSERT INTO Orders (CustomerID, Date)
VALUES (1, '2023-01-01');

SET @new_order_id = LAST_INSERT_ID();

INSERT INTO OrderItems (OrderID, ProductID, Count)
VALUES (@new_order_id, 1, 1);

UPDATE Products
SET WarehouseAmount = WarehouseAmount - 1
WHERE ID = 1;

COMMIT;
