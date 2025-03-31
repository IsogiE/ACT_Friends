# ACT

### For friends of Advance

This addon is designed for use within your guild. It’s **strongly advised** that **only officers** download ACT directly and then redistribute it **locally** (e.g., via Discord) to the rest of their guild.  
**Why?** Because some small configuration is required for officer access control.

---

## 🔧 Setup Instructions

After installing the addon:

1. Open `Nickname.lua`
2. Locate the function `IsPrivilegedUser()` (around **line 76**)
3. Manually input the **BattleTags** of your officers or raid leader

> ⚠️ **Note**: You’ll need to repeat this step **every time** you update the addon through WoWUp.

---

## 🧩 Addon Modules

You can open ACT using the `/act` command or by clicking the **Advance minimap icon**.

### 📛 Nicknames
Adds nickname support to:
- Default Raid Frames
- Grid2
- Cell
- ElvUI
- WeakAura `%unit` naming
- Liquid's WeakAura packs (natively supported due to collaboration with Liquid devs)
- MRT Note Assignments for the Liquid WeakAura packs or Liquid Timeline Reminder AddoN (e.g., if my nickname is set to Isogi but I'm playing Itsmeisogixd, entering Isogi in the MRT note will automatically resolve to my character and give it the relevant assignment or cooldown reminder from Timeline Reminders)
- MRT Raid Cooldown Bars

> **ElvUI Setup**:  
Raid frames will auto-import nicknames **except** for ElvUI. You’ll need to manually change your tag options from `[name]` or `[name:...]` to one of the following:
- `[nickname]`
- `[nickname:short]`
- `[nickname:medium]`

How To:  
`/ec → UnitFrames → Individual/Group Units → (Player/Party/Raid1 etc.) → Name`

**Notes:**
- Players that do not have nicknames will automatically return their player character names.
- If you prefer to display player character names on your Raid Frames or MRT Raid Cooldown Bars for characters that do have nicknames simply do `/ACT → Nicknames → Untick "Show nicknames on Party/Raid Frames & MRT Raid CDs`. All Raid Frames & MRT Raid Cooldown Bars will instead return player names. Unticking this checkbox does not break WeakAuras & (MRT Note) Assignments, they'll continue to resolve nicknames even with this option turned off. 

---

### 🖱️ Macros
A collection of commonly used **raid macros**.  
Clicking an icon generates a macro for that specific **world marker** or **icon**.

---

### 🔀 Split Helper
Helps ensure players are on the correct characters:
- Useful for split raids
- Also helpful for boss-specific setups with frequent swaps

---

### 🧪 Addon Checker
Checks raid members to verify:
- Presence of important raid addons
- Whether those addons are **up-to-date**

---

### 🔁 WeakAura Updater
Allows you to push **WeakAuras** directly to raid members:
- No more relying on Discord messages or manual imports
- Ideal for small auras or individual bosses (e.g., *if you manually updated the Rik Reverb auras from the Liquid package*)

---

### 🔍 Version Checker
Displays:
- Who in the raid has ACT installed
- What version they’re running

---

## 🧠 Addon Syntax

### 📛 Nicknames

Format:

```
Nickname: Char1, Char2; Nickname: Char3, Char4, Char5
```

- `:` starts a nickname definition and lists the characters it applies to.
- `;` starts a new nickname block.
- The last nickname entry **does not** require a trailing `;`.

**Notes:**
- Officers are encouraged to **push default nicknames** to raiders.
- Duplicate characters are automatically filtered out.
- **Officer defaults take precedence** over user-added nicknames, preventing raiders from disrupting assignments.

---

### ✂️ Split Helper

Format:

```
Char1, Char2, Char3, Char4, ...
```

- Maximum of **30 characters**.
- Going over the limit will result in an error message and abort the import.

---

### 📦 WeakAura Updater

- Use this to send **any WeakAura string**.
- Larger strings (and more players) = longer send time.
- Best used for **smaller auras** or **single-boss setups**.
