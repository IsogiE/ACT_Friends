# ACT Friends

### For friends of Advance

This addon is designed for use within your guild. It’s **strongly advised** that **only officers** download ACT Friends directly and then redistribute it **locally** (e.g., via Discord) to the rest of their guild members.  
**Why?** Because a small configuration is required for officer access control.

---

## 🔧 Setup Instructions

After installing the addon:

1. Open `Nickname.lua`.
2. Locate the function `IsPrivilegedUser()` (around **line 76**).
3. Manually input the **BattleTags** of your officers or raid leader.

> ⚠️ **Note**: You will need to redo this step **each time you update** the addon through WoWUp.

---

## 🧠 Addon Modules & Syntax

### 📛 Nicknames

Nicknames are imported using the following format:

```
Nickname: Char1, Char2; Nickname: Char1, Char2, Char3
```

- `:` starts a nickname definition and lists the characters it applies to.
- `;` starts a new nickname block.
- The final nickname does **not** need a trailing `;`.

**Note**
- It’s advised officers **push default nicknames** to raiders to prevent them deleting any important nicknames/characters.
- There is some protection baked in that duplicate characters will automatically be filtered out. Additionally Custom Nicknames from users will be overwritten by Officer's Default Nicknames as they take presedence over Custom ones to prevent raiders from making their own assigments unusable.

---

### ✂️ Split Helper

Format:

```
Char1, Char2, Char3, Char4, ...
```

- Supports up to **30 characters**.
- Exceeding this limit will show an error message and halt the import.

---

### 📦 WeakAura Updater

- Use this to send **any WeakAura string**.
- Larger strings (and more players) = longer send time.
- Recommended for **small WeakAuras** or **single boss encounters**, e.g., *Rik Reverb from the Liquid package*.
