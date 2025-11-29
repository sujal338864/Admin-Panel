// routes/bulkProducts.routes.js
const express = require("express");
const router = express.Router();
const multer = require("multer");
const xlsx = require("xlsx");
const { sql, poolPromise } = require("../models/db");

// ------------------------ MULTER ------------------------
const upload = multer({ storage: multer.memoryStorage() });

// ------------------------ SPEC FIELD MAP ------------------------
// ⚠️ These IDs must match your SpecificationFields.FieldID values.
// If you created fields in this order, this is fine.
const SPEC_FIELD_MAP = {
  Spec_Brand: 3,
  Spec_ModelName: 4,
  Spec_ModelNumber: 5,
  Spec_Color: 6,
  Spec_Material: 7,
  Spec_CountryOfOrigin: 8,
  Spec_Height: 9,
  Spec_Width: 10,
  Spec_Depth: 11,
  Spec_Weight: 12,
  Spec_Size: 13,
  Spec_KeyFeatures: 14,
  Spec_Usage: 15,
  Spec_WaterResistant: 16,
  Spec_SpecialFeatures: 17,
  Spec_Processor: 18,
  Spec_RAM: 19,
  Spec_Storage: 20,
  Spec_BatteryCapacity: 21,
  Spec_Connectivity: 22,
  Spec_WarrantySummary: 23,
  Spec_WarrantyDuration: 24,
  Spec_WarrantyType: 25,
  Spec_CoveredInWarranty: 26,
  Spec_NotCoveredInWarranty: 27,
  Spec_InTheBox: 28,
};

// ------------------------ HELPERS ------------------------
function safeNumber(v) {
  if (v === null || v === undefined || v === "") return null;
  const n = Number(v);
  return Number.isNaN(n) ? null : n;
}

function safeString(v) {
  if (v === undefined || v === null) return "";
  return String(v).trim();
}

function buildCombinationKey(row) {
  const parts = [];
  if (safeString(row["Variant_Color"]))
    parts.push(`Color:${safeString(row["Variant_Color"])}`);
  if (safeString(row["Variant_Size"]))
    parts.push(`Size:${safeString(row["Variant_Size"])}`);
  if (safeString(row["Variant_TVSize"]))
    parts.push(`TVSize:${safeString(row["Variant_TVSize"])}`);
  return parts.length ? parts.join("|") : null;
}

// ------------------------ CATEGORY/SUBCATEGORY/BRAND ------------------------
async function ensureCategoryId(tx, name) {
  const nm = safeString(name);
  if (!nm) return null;

  let r = await new sql.Request(tx)
    .input("name", sql.NVarChar, nm)
    .query("SELECT CategoryID FROM Categories WHERE Name=@name");

  if (r.recordset.length) return r.recordset[0].CategoryID;

  r = await new sql.Request(tx)
    .input("name", sql.NVarChar, nm)
    .query(
      "INSERT INTO Categories (Name, CreatedAt) OUTPUT INSERTED.CategoryID VALUES (@name, GETDATE())"
    );

  return r.recordset[0].CategoryID;
}

async function ensureSubcategoryId(tx, categoryId, name) {
  const nm = safeString(name);
  if (!nm || !categoryId) return null;

  let r = await new sql.Request(tx)
    .input("catId", sql.Int, categoryId)
    .input("name", sql.NVarChar, nm)
    .query(
      "SELECT SubcategoryID FROM Subcategories WHERE CategoryID=@catId AND Name=@name"
    );

  if (r.recordset.length) return r.recordset[0].SubcategoryID;

  r = await new sql.Request(tx)
    .input("catId", sql.Int, categoryId)
    .input("name", sql.NVarChar, nm)
    .query(
      "INSERT INTO Subcategories (Name, CategoryID, CreatedAt) OUTPUT INSERTED.SubcategoryID VALUES (@name,@catId,GETDATE())"
    );

  return r.recordset[0].SubcategoryID;
}

async function ensureBrandId(tx, subcategoryId, name) {
  const nm = safeString(name);
  if (!nm || !subcategoryId) return null;

  let r = await new sql.Request(tx)
    .input("subId", sql.Int, subcategoryId)
    .input("name", sql.NVarChar, nm)
    .query("SELECT BrandID FROM Brands WHERE SubcategoryID=@subId AND Name=@name");

  if (r.recordset.length) return r.recordset[0].BrandID;

  r = await new sql.Request(tx)
    .input("subId", sql.Int, subcategoryId)
    .input("name", sql.NVarChar, nm)
    .query(
      "INSERT INTO Brands (Name, SubcategoryID, CreatedAt) OUTPUT INSERTED.BrandID VALUES (@name,@subId,GETDATE())"
    );

  return r.recordset[0].BrandID;
}

// ------------------------ UPSERT PRODUCT ------------------------
async function upsertProduct(
  tx,
  row,
  { isParent, parentProduct, categoryId, subcategoryId, brandId }
) {
  const sku = safeString(row["SKU"]);
  if (!sku) throw new Error("SKU required.");

  const name = safeString(row["Name"]);
  const description = safeString(row["Description"]);
  const price = safeNumber(row["Price"]) ?? 0;
  const offerPrice = safeNumber(row["OfferPrice"]) ?? price;
  const qty = safeNumber(row["Quantity"]) ?? 0;
  const stock = safeNumber(row["Stock"]) ?? 0;
  const videoUrl = safeString(row["VideoUrl"]);

  const existing = await new sql.Request(tx)
    .input("sku", sql.NVarChar, sku)
    .query("SELECT TOP 1 * FROM Products WHERE SKU=@sku");

  if (existing.recordset.length === 0) {
    // INSERT
    const groupId = isParent
      ? Date.now() + Math.floor(Math.random() * 999)
      : parentProduct.GroupID;

    const r = await new sql.Request(tx)
      .input("name", sql.NVarChar, name)
      .input("desc", sql.NVarChar, description)
      .input("price", sql.Decimal(18, 2), price)
      .input("offer", sql.Decimal(18, 2), offerPrice)
      .input("qty", sql.Int, qty)
      .input("stock", sql.Int, stock)
      .input("catId", sql.Int, categoryId)
      .input("subId", sql.Int, subcategoryId)
      .input("brandId", sql.Int, brandId)
      .input("sku", sql.NVarChar, sku)
      .input("groupId", sql.BigInt, groupId)
      .input("parentId", sql.Int, isParent ? null : parentProduct.ProductID)
      .input("video", sql.NVarChar, videoUrl || null)
      .query(`
        INSERT INTO Products
        (Name, Description, Price, OfferPrice, Quantity, Stock,
         CategoryID, SubcategoryID, BrandID,
         SKU, GroupID, ParentProductID, VideoUrl,
         CreatedAt, UpdatedAt, IsSponsored)
        OUTPUT INSERTED.ProductID, INSERTED.GroupID
        VALUES
        (@name,@desc,@price,@offer,@qty,@stock,
         @catId,@subId,@brandId,
         @sku,@groupId,@parentId,@video,
         GETDATE(),GETDATE(),0)
      `);

    return r.recordset[0];
  } else {
    // UPDATE
    const pid = existing.recordset[0].ProductID;

    await new sql.Request(tx)
      .input("pid", sql.Int, pid)
      .input("name", sql.NVarChar, name)
      .input("desc", sql.NVarChar, description)
      .input("price", sql.Decimal(18, 2), price)
      .input("offer", sql.Decimal(18, 2), offerPrice)
      .input("qty", sql.Int, qty)
      .input("stock", sql.Int, stock)
      .input("catId", sql.Int, categoryId)
      .input("subId", sql.Int, subcategoryId)
      .input("brandId", sql.Int, brandId)
      .input("video", sql.NVarChar, videoUrl || null)
      .query(`
        UPDATE Products SET
          Name=@name,
          Description=@desc,
          Price=@price,
          OfferPrice=@offer,
          Quantity=@qty,
          Stock=@stock,
          CategoryID=@catId,
          SubcategoryID=@subId,
          BrandID=@brandId,
          VideoUrl=@video,
          UpdatedAt=GETDATE()
        WHERE ProductID=@pid
      `);

    return existing.recordset[0];
  }
}

// ------------------------ IMAGES (ProductImages table) ------------------------
async function upsertImages(tx, productId, row) {
  const imgs = [
    safeString(row["Image1"]),
    safeString(row["Image2"]),
    safeString(row["Image3"]),
  ].filter((x) => x);

  if (!imgs.length) return;

  // simple: always INSERT; no CombinationKey
  for (const url of imgs) {
    await new sql.Request(tx)
      .input("pid", sql.Int, productId)
      .input("url", sql.NVarChar, url)
      .query(
        "INSERT INTO ProductImages (ProductID, ImageURL) VALUES (@pid,@url)"
      );
  }
}

// ------------------------ SPECS (ProductSpecificationValues) ------------------------
async function upsertSpecs(tx, productId, row) {
  // delete old values for this product (same as /spec/product/save)
  await new sql.Request(tx)
    .input("pid", sql.Int, productId)
    .query("DELETE FROM ProductSpecificationValues WHERE ProductID=@pid");

  for (const [key, fieldId] of Object.entries(SPEC_FIELD_MAP)) {
    const val = safeString(row[key]);
    if (!val) continue;

    await new sql.Request(tx)
      .input("pid", sql.Int, productId)
      .input("fid", sql.Int, fieldId)
      .input("v", sql.NVarChar, val)
      .query(`
        INSERT INTO ProductSpecificationValues (ProductID, FieldID, Value)
        VALUES (@pid, @fid, @v)
      `);
  }
}

// ------------------------ MAIN BULK UPLOAD ROUTE ------------------------
router.post("/bulk-upload", upload.single("file"), async (req, res) => {
  if (!req.file)
    return res.status(400).json({ success: false, message: "No file uploaded" });

  try {
    const workbook = xlsx.read(req.file.buffer, { type: "buffer" });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = xlsx.utils.sheet_to_json(sheet, { defval: "" });

    if (!rows.length) {
      return res
        .status(400)
        .json({ success: false, message: "Excel sheet is empty" });
    }

    const pool = await poolPromise;
    const tx = new sql.Transaction(pool);
    await tx.begin();

    const parentCache = {}; // SKU -> { ProductID, GroupID }

    for (const row of rows) {
      const name = safeString(row["Name"]);
      const sku = safeString(row["SKU"]);
      const parentSku = safeString(row["ParentSKU"]);

      if (!name || !sku) continue;

      const isParent = !parentSku;

      // Category / Subcategory / Brand by name
      const categoryId = await ensureCategoryId(tx, row["CategoryName"]);
      const subcategoryId = await ensureSubcategoryId(
        tx,
        categoryId,
        row["SubcategoryName"]
      );
      const brandId = await ensureBrandId(tx, subcategoryId, row["BrandName"]);

      // Parent record for child rows
      let parentProduct = null;
      if (!isParent) {
        parentProduct = parentCache[parentSku];
        if (!parentProduct) {
          throw new Error(`Parent product with SKU "${parentSku}" not found (row with SKU ${sku})`);
        }
      }

      const inserted = await upsertProduct(tx, row, {
        isParent,
        parentProduct,
        categoryId,
        subcategoryId,
        brandId,
      });

      if (isParent) parentCache[sku] = inserted;

      // Images (Supabase URLs already in Excel)
      await upsertImages(tx, inserted.ProductID, row);

      // Specs
      await upsertSpecs(tx, inserted.ProductID, row);
    }

    await tx.commit();
    return res.json({
      success: true,
      message: `Bulk upload successful. Processed ${rows.length} rows.`,
    });
  } catch (err) {
    console.log("❌ BULK UPLOAD ERROR:", err);
    return res
      .status(500)
      .json({ success: false, message: "Bulk upload failed", error: err.message });
  }
});

module.exports = router;
