const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../models/db');  // ✅ Import DB

// ✅ GET SUBCATEGORIES BY CATEGORY ID
// Example: GET /api/user/subcategories?categoryId=1
// =====================================================
// ✅ GET SUBCATEGORIES (Filter by categoryId if provided)
// =====================================================
// ✅ GET all subcategories (filtered by categoryId if provided)
router.get("/", async (req, res) => {
  try {
    const { categoryId } = req.query;
    const pool = await poolPromise;

    let query = `
      SELECT 
        s.SubcategoryID AS SubcategoryID,
        s.Name AS Name,
        s.CategoryID AS CategoryID,
        c.Name AS CategoryName,
        s.CreatedAt
      FROM Subcategories s
      INNER JOIN Categories c ON s.CategoryID = c.CategoryID
    `;

    if (categoryId) query += ` WHERE s.CategoryID = @CategoryID`;

    const request = pool.request();
    if (categoryId) request.input("CategoryID", sql.Int, categoryId);

    const result = await request.query(query);
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Error fetching subcategories:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});


// =============================
// ✅ Add Subcategory
// Endpoint: POST /api/subcategories
// =============================
router.post('/', async (req, res) => {
  const { name, categoryId } = req.body;

  if (!name || !categoryId) {
    return res.status(400).json({ error: 'Name & CategoryId required' });
  }

  try {
    const pool = await poolPromise;
    await pool.request()
      .input('Name', sql.NVarChar, name)
      .input('CategoryID', sql.Int, categoryId)
      .query(`
        INSERT INTO Subcategories (Name, CategoryID, CreatedAt)
        VALUES (@Name, @CategoryID, GETDATE())
      `);

    res.status(201).json({ message: '✅ Subcategory created' });
  } catch (err) {
    console.error('❌ ADD subcategory error:', err);
    res.status(500).json({ error: err.message });
  }
});

// =============================
// ✅ Update Subcategory
// Endpoint: PUT /api/subcategories/:id
// =============================
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { name, categoryId } = req.body;

  if (!name || !categoryId) {
    return res.status(400).json({ error: 'Name & CategoryId required' });
  }

  try {
    const pool = await poolPromise;
    await pool.request()
      .input('ID', sql.Int, id)
      .input('Name', sql.NVarChar, name)
      .input('CategoryID', sql.Int, categoryId)
      .query(`
        UPDATE Subcategories
        SET Name = @Name, CategoryID = @CategoryID
        WHERE SubcategoryID = @ID
      `);

    res.json({ message: '✅ Subcategory updated' });
  } catch (err) {
    console.error('❌ UPDATE subcategory error:', err);
    res.status(500).json({ error: err.message });
  }
});

// =============================
// ✅ Delete Subcategory
// Endpoint: DELETE /api/subcategories/:id
// =============================
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const pool = await poolPromise;
    await pool.request()
      .input('ID', sql.Int, id)
      .query(`DELETE FROM Subcategories WHERE SubcategoryID = @ID`);

    res.json({ message: '✅ Subcategory deleted' });
  } catch (err) {
    console.error('❌ DELETE subcategory error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;


// const express = require('express');
// const sql = require('mssql');
// const router = express.Router();
// require('dotenv').config();

// const dbConfig = {
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD,
//   server: process.env.DB_SERVER,
//   database: process.env.DB_DATABASE,
//   port: parseInt(process.env.DB_PORT),
//   options: { encrypt: false, trustServerCertificate: true },
// };

// // ✅ GET all subcategories
// // ✅ GET all subcategories with category name!
// // ✅ routes/subcategory.js
// router.get('/', async (_, res) => {
//   try {
//     const pool = await poolPromise;
//     const result = await pool.request().query(`
//       SELECT 
//         SubcategoryID AS SubcategoryID,
//         Name AS Name,
//         CategoryID AS CategoryID
//       FROM Subcategories
//     `);
//     res.json(result.recordset);
//   } catch (err) {
//     console.error('❌ GET subcategories:', err);
//     res.status(500).json({ error: err.message });
//   }
// });
// // ✅ ADD subcategory
// router.post('/', async (req, res) => {
//   const { name, categoryId } = req.body;
//   if (!name || !categoryId) {
//     return res.status(400).json({ error: 'Name & CategoryId required' });
//   }
//   try {
//     const pool = await sql.connect(dbConfig);
//     await pool.request()
//       .input('name', sql.NVarChar, name)
//       .input('categoryId', sql.Int, categoryId)
//       .query(`
//         INSERT INTO Subcategories (Name, CategoryId, CreatedAt)
//         VALUES (@name, @categoryId, GETDATE())
//       `);
//     res.status(201).json({ message: '✅ Subcategory created' });
//   } catch (err) {
//     console.error('❌ ADD subcategory:', err);
//     res.status(500).json({ error: err.message });
//   }
// });

// // ✅ UPDATE subcategory
// router.put('/:id', async (req, res) => {
//   const { id } = req.params;
//   const { name, categoryId } = req.body;
//   if (!name || !categoryId) {
//     return res.status(400).json({ error: 'Name & CategoryId required' });
//   }
//   try {
//     const pool = await sql.connect(dbConfig);
//     await pool.request()
//       .input('id', sql.Int, id)
//       .input('name', sql.NVarChar, name)
//       .input('categoryId', sql.Int, categoryId)
//       .query(`
//         UPDATE Subcategories
//         SET Name = @name, CategoryId = @categoryId
//         WHERE Id = @id
//       `);
//     res.json({ message: '✅ Subcategory updated' });
//   } catch (err) {
//     console.error('❌ UPDATE subcategory:', err);
//     res.status(500).json({ error: err.message });
//   }
// });

// // ✅ DELETE subcategory
// router.delete('/:id', async (req, res) => {
//   const { id } = req.params;
//   try {
//     const pool = await sql.connect(dbConfig);
//     await pool.request()
//       .input('id', sql.Int, id)
//       .query(`DELETE FROM Subcategories WHERE Id = @id`);
//     res.json({ message: '✅ Subcategory deleted' });
//   } catch (err) {
//     console.error('❌ DELETE subcategory:', err);
//     res.status(500).json({ error: err.message });
//   }
// });

// module.exports = router;
