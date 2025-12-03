// const express = require("express");
// const router = express.Router();
// const sql = require("mssql");
// const db = require("../db");

// // GET all coupons
// router.get("/", async (req, res) => {
//   const result = await db.query("SELECT * FROM Coupons ORDER BY id DESC");
//   res.json(result.recordset);
// });

// // CREATE coupon
// router.post("/", async (req, res) => {
//   const { coupon_code, type, discount_amount, min_purchase, expiry_date, status } = req.body;

//   await db.query`
//     INSERT INTO Coupons (coupon_code, type, discount_amount, min_purchase, expiry_date, status)
//     VALUES (${coupon_code}, ${type}, ${discount_amount}, ${min_purchase}, ${expiry_date}, ${status})
//   `;

//   res.json({ message: "Coupon added" });
// });

// // UPDATE coupon
// router.put("/:id", async (req, res) => {
//   const { id } = req.params;
//   const { coupon_code, type, discount_amount, min_purchase, expiry_date, status } = req.body;

//   await db.query`
//     UPDATE Coupons SET
//       coupon_code=${coupon_code},
//       type=${type},
//       discount_amount=${discount_amount},
//       min_purchase=${min_purchase},
//       expiry_date=${expiry_date},
//       status=${status}
//     WHERE id=${id}
//   `;

//   res.json({ message: "Coupon updated" });
// });

// // DELETE coupon
// router.delete("/:id", async (req, res) => {
//   await db.query`DELETE FROM Coupons WHERE id=${req.params.id}`;
//   res.json({ message: "Coupon deleted" });
// });

// module.exports = router;
