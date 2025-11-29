// routes/brands.js
const express = require('express');
const sql = require('mssql');
const path = require('path');
const multer = require('multer');
const router = express.Router();
const { poolPromise } = require('../models/db');

// ⚠️ Make sure your Brands table has:
// BrandID (PK), Name, CategoryID (INT, NULL OK), SubcategoryID (INT), CreatedAt (default GETDATE())

// Multer setup (if you later add images)
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/brands/');
  },
  filename: function (req, file, cb) {
    cb(null, 'brand-' + Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

/**
 * ===============================
 *  GET /api/brands  → List brands
 * ===============================
 */
router.get('/', async (_, res) => {
  try {
    const pool = await poolPromise;

    const result = await pool.request().query(`
      SELECT 
        b.BrandID,
        b.Name,
        b.CategoryID,
        b.SubcategoryID,
        b.CreatedAt,
        ISNULL(c.Name, '') AS CategoryName,
        ISNULL(s.Name, '') AS SubcategoryName
      FROM Brands b
      LEFT JOIN Categories c ON b.CategoryID = c.CategoryID
      LEFT JOIN Subcategories s ON b.SubcategoryID = s.SubcategoryID
      ORDER BY b.BrandID ASC;
    `);

    res.status(200).json(result.recordset);
  } catch (err) {
    console.error('❌ GET /brands:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * ===============================
 *  POST /api/brands  → Create brand
 * ===============================
 * body: { name, categoryId, subcategoryId }
 */
router.post('/', async (req, res) => {
  try {
    const { name, categoryId, subcategoryId } = req.body;

    if (!name || !subcategoryId) {
      return res
        .status(400)
        .json({ message: 'Name and subcategoryId are required' });
    }

    const pool = await poolPromise;

    await pool
      .request()
      .input('name', sql.NVarChar, name)
      .input('categoryId', sql.Int, categoryId || null)
      .input('subcategoryId', sql.Int, subcategoryId)
      .query(`
        INSERT INTO Brands (Name, CategoryID, SubcategoryID, CreatedAt)
        VALUES (@name, @categoryId, @subcategoryId, GETDATE());
      `);

    res.status(201).json({ message: 'Brand created successfully' });
  } catch (err) {
    console.error('❌ POST /brands:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * ===============================
 *  PUT /api/brands/:id  → Update brand
 * ===============================
 * body: { name, categoryId, subcategoryId }
 */
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { name, categoryId, subcategoryId } = req.body;

  if (!name || !subcategoryId) {
    return res
      .status(400)
      .json({ message: 'Name and subcategoryId are required' });
  }

  try {
    const pool = await poolPromise;

    await pool
      .request()
      .input('id', sql.Int, id)
      .input('name', sql.NVarChar, name)
      .input('categoryId', sql.Int, categoryId || null)
      .input('subcategoryId', sql.Int, subcategoryId)
      .query(`
        UPDATE Brands 
        SET 
          Name = @name,
          CategoryID = @categoryId,
          SubcategoryID = @subcategoryId
        WHERE BrandID = @id;
      `);

    res.json({ message: 'Brand updated successfully' });
  } catch (err) {
    console.error('❌ PUT /brands:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * ===============================
 *  DELETE /api/brands/:id
 * ===============================
 */
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const pool = await poolPromise;

    await pool
      .request()
      .input('id', sql.Int, id)
      .query(`DELETE FROM Brands WHERE BrandID = @id;`);

    res.json({ message: 'Brand deleted successfully' });
  } catch (err) {
    console.error('❌ DELETE /brands:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
