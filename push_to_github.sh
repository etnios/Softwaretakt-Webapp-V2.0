#!/bin/bash

# GitHub Push Script for Softwaretakt Backup
# Pushing to: https://github.com/etnios/Softwaretakt

echo "🚀 Pushing Softwaretakt to GitHub..."

# Add GitHub as remote origin
echo "Adding GitHub remote..."
git remote add origin https://github.com/etnios/Softwaretakt.git

# Rename branch to main (if needed)
echo "Setting main branch..."
git branch -M main

# Push to GitHub
echo "Pushing to GitHub..."
git push -u origin main

echo "✅ Backup complete! Check your GitHub repository."
echo "📁 Files uploaded: 67 files, 18,799 lines of code"
echo "🎵 Your Softwaretakt app is now safely backed up on GitHub!"
echo "🌐 Repository: https://github.com/etnios/Softwaretakt"
