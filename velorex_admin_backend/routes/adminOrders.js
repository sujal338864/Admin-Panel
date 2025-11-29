const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

/* =====================================================
   🟣 ADMIN: GET ALL ORDERS (Flattened Order Items)
   ===================================================== */
router.get("/", async (req, res) => {
  try {
    const pool = await poolPromise;

    const result = await pool.request().query(`
      SELECT 
        o.orderId,
        o.userId,
        u.Name AS userName,
        u.Email AS userEmail,
        o.totalAmount,
        o.paymentMethod,
        o.shippingAddress,
        o.orderStatus,
        o.createdAt,
        oi.orderItemId,
        oi.productId,
        oi.quantity,
        oi.price AS itemPrice,
        oi.orderItemStatus,
        oi.ItemTrackingUrl,
        p.Name AS productName,
        (
          SELECT STRING_AGG(pi.ImageURL, ',')
          FROM ProductImages pi WHERE pi.ProductID = p.ProductID
        ) AS imageUrls
      FROM Orders o
      INNER JOIN OrderItems oi ON o.orderId = oi.orderId
      LEFT JOIN Products p ON oi.productId = p.ProductID
      LEFT JOIN Users u ON o.userId = u.UserID
      ORDER BY o.createdAt DESC
    `);

const orders = result.recordset.map((row) => ({
  orderId: Number(row.orderId),
  orderItemId: row.orderItemId,
  userId: row.userId,
  userName: row.userName || "Unknown",
  userEmail: row.userEmail || "N/A",
  totalAmount: Number(row.totalAmount),
  paymentMethod: row.paymentMethod,
  shippingAddress: row.shippingAddress,
  orderStatus: row.orderStatus,
  createdAt: row.createdAt,
  productId: row.productId,
  productName: row.productName,
  quantity: row.quantity,
  price: row.itemPrice,

  // 🟢 FIXED HERE
  orderItemStatus:
    row.orderItemStatus && row.orderItemStatus.trim() !== ""
      ? row.orderItemStatus.trim()
      : "Pending",

  trackingUrl: row.ItemTrackingUrl,
  imageUrls: row.imageUrls
    ? row.imageUrls.split(",").map((url) => url.trim())
    : ["https://via.placeholder.com/300?text=No+Image"],
}));


    res.json({ success: true, data: orders });
  } catch (error) {
    console.error("❌ Admin fetch all orders error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/* =====================================================
   🟢 ADMIN: GET SINGLE ORDER DETAILS (Items Included)
   ===================================================== */
router.get("/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    const pool = await poolPromise;

    const orderResult = await pool.request()
      .input("OrderID", sql.Int, orderId)
      .query(`
        SELECT 
          o.orderId,
          o.userId,
          u.Name AS userName,
          u.Email AS userEmail,
          o.totalAmount,
          o.paymentMethod,
          o.orderStatus,
          o.createdAt,
          o.shippingAddress
        FROM Orders o
        LEFT JOIN Users u ON o.userId = u.UserID
        WHERE o.orderId = @OrderID
      `);

    if (orderResult.recordset.length === 0) {
      return res.status(404).json({ success: false, message: "Order not found" });
    }

    const order = orderResult.recordset[0];

    const itemsResult = await pool.request()
      .input("OrderID", sql.Int, orderId)
      .query(`
        SELECT 
          oi.orderItemId,
          oi.productId,
          p.Name AS productName,
          oi.quantity,
          oi.price,
          ISNULL(oi.orderItemStatus, 'Pending') AS orderItemStatus,
          ISNULL(oi.ItemTrackingUrl, '') AS trackingUrl,
          (
            SELECT STRING_AGG(pi.ImageURL, ',')
            FROM ProductImages pi WHERE pi.ProductID = p.ProductID
          ) AS imageUrls
        FROM OrderItems oi
        LEFT JOIN Products p ON oi.ProductID = p.ProductID
        WHERE oi.OrderID = @OrderID
      `);

    order.items = itemsResult.recordset.map((item) => ({
      orderItemId: item.orderItemId,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      price: item.price,
      orderItemStatus: item.orderItemStatus,
      trackingUrl: item.trackingUrl,
      imageUrls: item.imageUrls
        ? item.imageUrls.split(",").map((url) => url.trim())
        : ["https://via.placeholder.com/300?text=No+Image"],
    }));

    res.json({ success: true, data: order });
  } catch (err) {
    console.error("❌ Error fetching order:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/* =====================================================
   🟠 ADMIN: UPDATE SINGLE ORDER ITEM
   (Status & Tracking URL)
   ===================================================== */
router.put("/item/:orderItemId/update", async (req, res) => {
  const { orderItemId } = req.params;
  const { status, trackingUrl } = req.body;

  if (!status && !trackingUrl) {
    return res.status(400).json({
      success: false,
      message: "At least one field (status or trackingUrl) is required",
    });
  }

  try {
    const pool = await poolPromise;

    const result = await pool.request()
      .input("orderItemId", sql.Int, orderItemId)
      .input("orderItemStatus", sql.NVarChar, status || null)
      .input("trackingUrl", sql.NVarChar, trackingUrl || null)
      .query(`
        UPDATE OrderItems
        SET 
          orderItemStatus = COALESCE(@orderItemStatus, orderItemStatus),
          ItemTrackingUrl = COALESCE(@trackingUrl, ItemTrackingUrl)
        WHERE orderItemId = @orderItemId;

        SELECT * FROM OrderItems WHERE orderItemId = @orderItemId;
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({ success: false, message: "Order item not found" });
    }

    res.json({
      success: true,
      message: "Order item updated successfully",
      updated: result.recordset[0],
    });
  } catch (error) {
    console.error("❌ Update order item error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/* =====================================================
   🟢 ADMIN: UPDATE MAIN ORDER STATUS
   ===================================================== */
router.put("/:orderId/status", async (req, res) => {
  const { orderId } = req.params;
  const { status } = req.body;

  if (!status)
    return res.status(400).json({ success: false, message: "Status required" });

  try {
    const pool = await poolPromise;

    const result = await pool.request()
      .input("orderId", sql.Int, orderId)
      .input("status", sql.NVarChar, status)
      .query(`
        UPDATE Orders
        SET orderStatus = @status
        WHERE orderId = @orderId;

        SELECT * FROM Orders WHERE orderId = @orderId;
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({ success: false, message: "Order not found" });
    }

    res.json({
      success: true,
      message: "Order status updated successfully",
      updated: result.recordset[0],
    });
  } catch (error) {
    console.error("❌ Order status update error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/* =====================================================
   🔴 DELETE ORDER & ITEMS
   ===================================================== */
router.delete("/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    const pool = await poolPromise;

    await pool.request()
      .input("OrderID", sql.Int, orderId)
      .query("DELETE FROM OrderItems WHERE OrderID = @OrderID");

    await pool.request()
      .input("OrderID", sql.Int, orderId)
      .query("DELETE FROM Orders WHERE OrderID = @OrderID");

    res.status(200).json({
      success: true,
      message: `Order #${orderId} deleted successfully`,
    });
  } catch (err) {
    console.error("❌ Delete order error:", err);
    res.status(500).json({ success: false, message: "Failed to delete order" });
  }
});

module.exports = router;
