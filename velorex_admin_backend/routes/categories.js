const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../models/db');

// ✅ Get all categories
router.get('/', async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .query('SELECT CategoryID, Name, ImageUrl, CreatedAt FROM Categories ORDER BY CreatedAt DESC');
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ✅ Add category with image URL
router.post('/', async (req, res) => {
  const { name, imageUrl } = req.body;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input('name', sql.NVarChar, name)
      .input('imageUrl', sql.NVarChar, imageUrl)
      .query(`
        INSERT INTO Categories (Name, ImageUrl)
        VALUES (@name, @imageUrl)
      `);
    res.status(201).json({ message: 'Category added successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ✅ Update category
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { name, imageUrl } = req.body;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input('id', sql.Int, id)
      .input('name', sql.NVarChar, name)
      .input('imageUrl', sql.NVarChar, imageUrl)
      .query(`
        UPDATE Categories 
        SET Name = @name, ImageUrl = @imageUrl 
        WHERE CategoryID = @id
      `);
    res.json({ message: 'Category updated successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ✅ Delete category
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM Categories WHERE CategoryID = @id');
    res.json({ message: 'Category deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
// const express = require('express');
// const router = express.Router();
// const { sql, poolPromise } = require('../models/db');

// // ✅ GET all categories
// router.get('/', async (req, res) => {
//   try {
//     const pool = await poolPromise;
//     const result = await pool.request()
//       .query('SELECT CategoryID, Name, CreatedAt FROM Categories ORDER BY CreatedAt DESC');
//     res.json(result.recordset);
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: err.message });
//   }
// });



// // ✅ Add category
// router.post('/', async (req, res) => {
//   const { name } = req.body;
//   try {
//     const pool = await poolPromise;
//     await pool.request()
//       .input('name', sql.NVarChar, name)
//       .query(`INSERT INTO Categories (Name) VALUES (@name)`);
//     res.status(201).json({ message: 'Category added' });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: err.message });
//   }
// });

// // ✅ Update category
// router.put('/:id', async (req, res) => {
//   const { id } = req.params;
//   const { name } = req.body;
//   try {
//     const pool = await poolPromise;
//     await pool.request()
//       .input('id', sql.Int, id)
//       .input('name', sql.NVarChar, name)
//       .query(`UPDATE Categories SET Name = @name WHERE CategoryID = @id`);
//     res.json({ message: 'Category updated' });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: err.message });
//   }
// });

// // ✅ Delete category
// router.delete('/:id', async (req, res) => {
//   const { id } = req.params;
//   try {
//     const pool = await poolPromise;
//     await pool.request()
//       .input('id', sql.Int, id)
//       .query(`DELETE FROM Categories WHERE CategoryID = @id`);
//     res.json({ message: 'Category deleted' });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: err.message });
//   }
// });

// module.exports = router;
