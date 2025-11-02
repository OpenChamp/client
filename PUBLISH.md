## 🚀 Publishing a Release

### Option 1: Using Helper Script (Recommended)
```bash
# macOS/Linux
./release.sh v0.0.0

# Windows
release.bat v0.0.0
```

### Option 2: Git Commands
```bash
git tag -a v0.0.0 -m "Release v0.0.0"
git push origin v0.0.0
```

### Option 3: GitHub UI
1. Go to GitHub → Actions
2. Select "Manual Build and Release"
3. Click "Run workflow"
4. Enter version (1.0.0)
5. Click "Run workflow"

---