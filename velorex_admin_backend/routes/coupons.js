const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../models/db');

// ✅ Get all coupons
router.get('/', async (_, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request().query('SELECT * FROM Coupons');
    res.status(200).json(result.recordset);
  } catch (err) {
    console.error('❌ GET /api/coupons:', err);
    res.status(500).json({ error: err.message });
  }
});

// ✅ Add a coupon
router.post('/', async (req, res) => {
  const {
    code,
    discountType,
    discountAmount,
    minimumPurchase,
    startDate,
    endDate,
    status,
    categoryId,
    subcategoryId,
    productId
  } = req.body;

  try {
    const pool = await poolPromise;
   await pool.request()
  .input('Code', sql.NVarChar, code)
  .input('DiscountType', sql.NVarChar, discountType)
  .input('DiscountAmount', sql.Decimal(18, 2), discountAmount)
  .input('MinimumPurchase', sql.Decimal(18, 2), minimumPurchase)
  .input('StartDate', sql.DateTime, startDate)
  .input('EndDate', sql.DateTime, endDate)
  .input('Status', sql.NVarChar, status)
  .input('CategoryID', sql.Int, categoryId != null ? categoryId : null)
  .input('SubcategoryID', sql.Int, subcategoryId != null ? subcategoryId : null)
  .input('productId', sql.Int, productId != null ? productId : null)  // ✅ FIXED HERE
  .query(`
    INSERT INTO Coupons
      (Code, DiscountType, DiscountAmount, MinimumPurchase, StartDate, EndDate, Status, CategoryID, SubcategoryID, productId)
    VALUES
      (@Code, @DiscountType, @DiscountAmount, @MinimumPurchase, @StartDate, @EndDate, @Status, @CategoryID, @SubcategoryID, @productId)
  `);


    res.status(201).json({ message: '✅ Coupon added successfully' });
  } catch (err) {
    console.error('❌ POST /api/coupons:', err);
    res.status(500).json({ error: err.message });
  }
});


// ✅ Delete a coupon
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const pool = await poolPromise;
    await pool.request()
      .input('ID', sql.Int, id)
      .query('DELETE FROM Coupons WHERE CouponID = @ID');

    res.status(200).json({ message: '✅ Coupon deleted successfully' });
  } catch (err) {
    console.error('❌ DELETE /api/coupons:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
