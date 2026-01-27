const express = require("express");
const app = express();

const path = require("path");

app.use(express.static(path.join(__dirname, "../public")));

app.get("/api/status", (req, res) => {
    res.status(200).json({ message: "Hello World!" });
});
module.exports = app;
