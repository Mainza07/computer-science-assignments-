DELIMITER //

CREATE PROCEDURE pr_record_sale(
    IN p_medicine_id INT, 
    IN p_quantity INT, 
    IN p_sold_on DATE
)
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_current_price DECIMAL(10,2);
    
    -- Start transaction to ensure atomicity
    START TRANSACTION;
    
    -- Get current stock and price
    SELECT stock_qty, unit_price INTO v_current_stock, v_current_price
    FROM medicines 
    WHERE medicine_id = p_medicine_id;
    
    -- Check if medicine exists and there is enough stock
    IF v_current_stock IS NOT NULL AND v_current_stock >= p_quantity AND p_quantity > 0 THEN
        
        -- 1. Insert into sales (assuming sale_id is auto-increment)
        INSERT INTO sales (medicine_id, quantity, unit_price, sold_on)
        VALUES (p_medicine_id, p_quantity, v_current_price, p_sold_on);
        
        -- 2. Deduct stock
        UPDATE medicines 
        SET stock_qty = stock_qty - p_quantity 
        WHERE medicine_id = p_medicine_id;
        
        COMMIT;
    ELSE
        -- Invalid sale: rollback (leaves tables unchanged)
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid sale: Insufficient stock or invalid medicine/quantity.';
    END IF;
    
END //

DELIMITER ;