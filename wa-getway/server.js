const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require("@whiskeysockets/baileys");
const express = require("express");
const pino = require("pino");
const qrcode = require("qrcode");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(express.json());

// Allow browser requests from Next.js frontend
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
});


const API_KEY = "MEDIKA-SECRET-KEY";
let sock = null;
let qrCodeBase64 = null;
let connectionStatus = "disconnected";

async function startWA() {
    console.log("🔄 Mencoba menghubungkan ke WhatsApp...");
    connectionStatus = "connecting";
    
    const sessionPath = path.join(__dirname, 'session');
    const { state, saveCreds } = await useMultiFileAuthState('session');
    
    let version = [2, 3000, 1015901307];
    try {
        const latest = await fetchLatestBaileysVersion();
        version = latest.version;
    } catch (e) {}

    sock = makeWASocket({
        version,
        auth: state,
        logger: pino({ level: "silent" }),
        browser: ["Mac OS", "Safari", "10.15.7"],
    });

    sock.ev.on("connection.update", async (update) => {
        const { connection, lastDisconnect, qr } = update;
        
        if (qr) {
            connectionStatus = "pairing";
            qrCodeBase64 = await qrcode.toDataURL(qr);
            console.log("👉 [INFO] QR Code siap di Admin Panel.");
        }

        if (connection === "close") {
            const reason = lastDisconnect?.error?.output?.statusCode;
            qrCodeBase64 = null;
            connectionStatus = "disconnected";
            console.log(`📡 Koneksi ditutup. Alasan: ${reason}`);
            
            // Jika 401 (Unauthorized) atau 405, hapus sesi dan mulai baru
            if (reason === 401 || reason === 405) {
                console.log("⚠️  Sesi tidak sah. Menghapus folder session...");
                if (fs.existsSync(sessionPath)) {
                    fs.rmSync(sessionPath, { recursive: true, force: true });
                }
                setTimeout(startWA, 3000);
            } else if (reason !== DisconnectReason.loggedOut) {
                console.log("🔄 Mencoba menghubungkan kembali dalam 5 detik...");
                setTimeout(startWA, 5000);
            }
        } else if (connection === "open") {
            qrCodeBase64 = null;
            connectionStatus = "connected";
            console.log("\n✅ [BERHASIL] WHATSAPP MEDIKA ONLINE!");
        }
    });

    sock.ev.on("creds.update", saveCreds);
}

app.get("/status", (req, res) => {
    res.json({
        status: connectionStatus,
        qr: qrCodeBase64
    });
});

app.post("/logout", async (req, res) => {
    console.log("📥 [LOGOUT] Menerima permintaan...");
    try {
        if (sock) {
            await sock.logout();
            sock = null;
        }
        const sessionPath = path.join(__dirname, 'session');
        if (fs.existsSync(sessionPath)) {
            fs.rmSync(sessionPath, { recursive: true, force: true });
        }
        connectionStatus = "disconnected";
        qrCodeBase64 = null;
        setTimeout(startWA, 2000);
        res.json({ status: "success", message: "Logged out" });
    } catch (e) {
        res.status(500).json({ status: "error", message: e.message });
    }
});

app.post("/send-message", async (req, res) => {
    const { number, message, api_key } = req.body;
    if (api_key !== API_KEY) return res.status(401).json({ status: "error", message: "API Key Salah!" });
    if (!sock || connectionStatus !== "connected") return res.status(500).json({ status: "error", message: "WhatsApp belum terhubung!" });

    try {
        const cleanNumber = number.replace(/[^0-9]/g, "");
        const jid = `${cleanNumber}@s.whatsapp.net`;
        await sock.sendMessage(jid, { text: message });
        res.json({ status: "success", message: "Pesan terkirim" });
        console.log(`[SEND] Ke: ${number}`);
    } catch (err) {
        res.status(500).json({ status: "error", message: err.message });
    }
});

const PORT = 3001;
app.listen(PORT, () => {
    console.log(`\n🚀 [SERVER] MEDIKA GATEWAY AKTIF DI PORT ${PORT}`);
    startWA();
});
