const express = require('express');
const sql = require('mssql');
const router = express.Router();
const { poolPromise } = require('../models/db'); // Make sure this points to your db config

// ---------------- GET all variant types ----------------
router.get('/', async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .query("SELECT * FROM VariantTypes ORDER BY VariantTypeID DESC");
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------- POST add new variant type ----------------
router.post('/', async (req, res) => {
  try {
    const { variantName, variantType } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input("VariantName", sql.NVarChar, variantName)
      .input("VariantType", sql.NVarChar, variantType)
      .query("INSERT INTO VariantTypes (VariantName, VariantType, AddedDate) VALUES (@VariantName, @VariantType, GETDATE())");

    res.status(201).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------- PUT update variant type ----------------
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { variantName, variantType } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input("id", sql.Int, id)
      .input("VariantName", sql.NVarChar, variantName)
      .input("VariantType", sql.NVarChar, variantType)
      .query("UPDATE VariantTypes SET VariantName = @VariantName, VariantType = @VariantType WHERE VariantTypeID = @id");

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------- DELETE variant type ----------------
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await poolPromise;

    await pool.request()
      .input('id', sql.Int, id)
      .query("DELETE FROM VariantTypes WHERE VariantTypeID = @id");

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;