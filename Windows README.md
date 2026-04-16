# 🐘 hadoop-installer (Windows)

> Install Apache Hadoop 3.2.3 on **Windows 10/11** in the simplest way possible — just **2 steps**.
> Uses **WSL2 (Ubuntu 22.04)** under the hood, so all Hadoop behaviour is identical to a native Linux install.

---

## ✅ Requirements

| Requirement | Details |
|---|---|
| **OS** | Windows 10 (build 19041+) or Windows 11 |
| **Privileges** | Administrator account |
| **RAM** | 4 GB minimum, 8 GB recommended |
| **Disk** | ~5 GB free space |
| **Internet** | Required during installation |

> To check your Windows build: `Win + R` → type `winver` → press Enter.

---

## 🚀 Installation — Only 2 Steps

### Step 1 — Download both files into the same folder

```
install_hadoop.ps1      ← Windows PowerShell installer
install_hadoop.sh       ← Linux installer (used automatically inside WSL)
```

> Clone the repo:
> ```powershell
> git clone https://github.com/YOUR_USERNAME/hadoop-installer.git
> cd hadoop-installer
> ```
> Or download both files manually and place them in the **same folder**.

---

### Step 2 — Run the installer as Administrator

1. Open the folder containing the files
2. Right-click `install_hadoop.ps1` → **"Run with PowerShell"**
   — OR —
   Open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install_hadoop.ps1
```

> ⚠️ Do **NOT** run as a regular (non-admin) PowerShell window.

---

## 🔄 What the Installer Does (Automatically)

| Step | Action |
|---|---|
| 1 | Enables WSL2 and Virtual Machine Platform Windows features |
| 2 | Downloads and installs the WSL2 Linux kernel update |
| 3 | Installs **Ubuntu 22.04 LTS** from the Microsoft Store |
| 4 | Copies `install_hadoop.sh` into Ubuntu and runs it |
| 5 | Creates 3 helper `.bat` shortcuts on your Desktop |

> ⚠️ If Windows features were not previously enabled, **a restart may be required**
> after Step 1. Simply re-run the script after restarting — it is safe to re-run.

---

## 🔑 During Installation

When the Ubuntu installer runs, it will prompt you to **set a password for the new `hadoop` user**.

**Suggested password:** `hadoop`

```
Enter new UNIX password: hadoop
Retype new UNIX password: hadoop
```

Press **Enter** through any remaining prompts (Full Name, Room Number, etc.).

---

## ✔️ Verify the Installation

Open a command prompt or PowerShell and run:

```powershell
wsl -d Ubuntu-22.04 -u hadoop -- jps
```

You should see all **5 daemons**:

```
12345 NameNode
12346 DataNode
12347 SecondaryNameNode
12348 ResourceManager
12349 NodeManager
```

---

## 🖥️ Desktop Shortcuts

Three `.bat` files are placed on your Desktop automatically:

| File | Purpose |
|---|---|
| `start-hadoop.bat` | Start all Hadoop daemons |
| `stop-hadoop.bat` | Stop all Hadoop daemons |
| `hadoop-shell.bat` | Open a WSL shell as the `hadoop` user |

Double-click any of these to use them.

---

## 🧪 Quick Smoke Test

Double-click `hadoop-shell.bat` (or run `wsl -d Ubuntu-22.04 -u hadoop`), then:

```bash
hdfs dfs -mkdir /test
hdfs dfs -ls /
```

Expected output:

```
Found 1 items
drwxr-xr-x  - hadoop supergroup  0  2024-01-01  /test
```

---

## 🌐 Web UIs

After installation, open these in your **Windows browser** (Chrome, Edge, etc.):

| Service | URL |
|---|---|
| HDFS NameNode | http://localhost:9870 |
| YARN Resource Manager | http://localhost:8088 |
| Secondary NameNode | http://localhost:9868 |

WSL2 automatically exposes Linux ports to Windows localhost — no extra configuration needed.

---

## 📁 What Gets Installed

| Component | Details |
|---|---|
| **Hadoop version** | 3.2.3 |
| **Java** | OpenJDK 8 (inside WSL) |
| **WSL distro** | Ubuntu 22.04 LTS |
| **Install location** | `/home/hadoop/hadoop-3.2.3` (inside WSL) |
| **HDFS data** | `/home/hadoop/dfsdata/` (inside WSL) |
| **Temp directory** | `/home/hadoop/tmpdata/` (inside WSL) |
| **Config files** | `core-site.xml`, `hdfs-site.xml`, `mapred-site.xml`, `yarn-site.xml` |

---

## ❓ Troubleshooting

**Execution policy error?**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install_hadoop.ps1
```

**WSL not found / wsl command fails?**
- Ensure you are on Windows 10 build 19041+ or Windows 11
- Run Windows Update and try again

**A daemon is missing from `jps`?**
```powershell
wsl -d Ubuntu-22.04 -u hadoop -- bash -c "cat /home/hadoop/hadoop-3.2.3/logs/*.log | tail -50"
```

**SSH issues inside WSL?**
```powershell
wsl -d Ubuntu-22.04 -- bash -c "sudo service ssh status; sudo service ssh start"
```

**Port already in use (9870 / 8088)?**
Check if another process is using the port:
```powershell
netstat -ano | findstr :9870
```

**Re-running the script?**
Safe to re-run. WSL distro install and user creation are skipped if already done.
> ⚠️ Re-running **will reformat the NameNode**, which erases existing HDFS data.

---

## 🔁 Starting Hadoop After a Reboot

Hadoop does **not** start automatically on Windows restart. Use the Desktop shortcut:

```
Double-click → start-hadoop.bat
```

Or from PowerShell:
```powershell
wsl -d Ubuntu-22.04 -u hadoop -- bash -c "start-dfs.sh && start-yarn.sh"
```

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

<p align="center">Made with ❤️ to make Hadoop setup painless on Windows</p>
