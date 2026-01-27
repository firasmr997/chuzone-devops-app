const request = require("supertest");
const app = require("../src/app");

describe("GET /api/status", () => {
    it("should return status 200", async () => {
        const res = await request(app).get("/api/status");
        expect(res.statusCode).toBe(200);
    });
});
