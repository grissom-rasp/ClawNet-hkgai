# ClawNet User Guide

## What Is This?

ClawNet is an AI assistant platform that runs on your Mac. After you open the app, AI assistants can help you:

- Organize files on your computer (move, rename, categorize, archive)
- Search and read file contents
- Delete files you no longer need (and restore them at any time)
- Communicate and collaborate with other people’s AI assistants

You can tell the assistant what you want in natural language, just like chatting with a real person.

---

## Quick Start

### Step 1: Authorize Folders

Open the app -> Settings -> Security -> File Access Control:

1. Choose "Limited Scope (Allowlist)" mode
2. Click "Choose Folder..." and select the folders you want the AI assistant to access
3. You can add multiple folders and remove them at any time

> The AI assistant can only operate inside folders you authorized. It cannot access files elsewhere.

### Step 2: Start a Conversation

In the conversation list on the left, click "+" to create a new chat, then directly tell the assistant what you want:

- "Help me check what files are in Documents"
- "Organize files in Downloads by type"
- "Find PDFs with 'report' in the name"

---

## Tags: Let Different Assistants Handle Different Things

### Why Tags Matter

Imagine this: you don’t want your work assistant to see your private photos, and you don’t want your personal assistant to browse work contracts. Tags solve this by **limiting what folders each assistant can access**.

### Assistants You’ll Have

| Assistant | Purpose | What It Can See |
|------|------|-----------|
| **Main Assistant** | Your all-around assistant | All folders you authorized |
| **Work Assistant** (created by you) | Handles work-related tasks | Only the work folders you specify |
| **Personal Assistant** (created by you) | Handles personal tasks | Only the personal folders you specify |

The **Main Assistant** has the broadest permissions and can see everything you authorized, so it is suitable for tasks that span multiple areas. Other assistants are isolated and focused on their own scope.

### Setup Example: Separate Work and Personal

Suppose your files are organized like this:

```
Documents/
  Work/
  Personal/
  Shared/
```

**1. Authorize folders first**

Settings -> Security -> Choose Folder: authorize all three folders above

**2. Create a "Work" tag**

Settings -> Tag Management -> click "+" -> enter name "Work" -> select "Work" and "Shared"

**3. Create a "Personal" tag**

Same process, select "Personal" and "Shared"

**4. Start using them**

- Chat with the **Work Assistant** -> it only sees Work and Shared
- Chat with the **Personal Assistant** -> it only sees Personal and Shared
- Chat with the **Main Assistant** -> it sees all three

---

## What You Can Ask the Assistant to Do

### View and Search Files

Use everyday language:

- "List my Documents directory"
- "Sort by modified time and show recently changed files"
- "Recursively list all files under projects"
- "Find files with 'quarterly report' in the name"
- "Tell me what this PDF says"
- "How large is this file? When was it created?"

### Organize Files

- "Create an archive directory"
- "Move this file to archive"
- "Rename draft.md to final.md"
- "Copy one version to backup"
- "Help me organize files in Downloads by type"

### Delete Files (Safe Delete, Recoverable)

- "Delete this file" -> file is moved to Trash, not permanently deleted
- "I deleted the wrong one, restore it" -> assistant finds the record and restores it
- "Show what operations you just did" -> view operation history
- "Undo the last action" -> one-click undo
- "Undo all operations you just performed" -> batch rollback (with preview before confirmation)

### Write to Files

- "Save this text to notes.md"
- "Append a summary at the end of report.md"

If the assistant overwrites an existing file, the previous version is automatically backed up and can be restored via undo.

---

## Operation History and Undo

Every file operation performed by the assistant is logged. At any time, you can:

- **View history**: "Show me what operations you performed"
- **Undo one operation**: "Undo that last delete" or "Undo that move operation"
- **Undo in bulk**: "Undo all recent operations" (assistant previews exactly what will be undone and asks for confirmation)

**Important:** each assistant can only view and undo operations it performed in the current conversation. It does not affect other assistants’ operations.

---

## Communicating with Other People’s Assistants (A2A)

### What Is A2A?

Your assistant can talk directly with other people’s assistants. For example, your work assistant can coordinate with a colleague’s work assistant and exchange project-related information.

### How to Use It

**1. Add contacts**

Sidebar -> Contacts -> click "+" -> enter the other person’s email -> send request

**2. After they accept**

You will see their assistant in your conversation list. Click to start chatting.

**3. When you receive a message from their assistant**

The system prepares two draft replies for you:

| Draft | Source | Best For |
|------|------|-------------|
| **Tag Assistant Draft** | Assistant for the corresponding tag | Questions within that tag’s scope (e.g., work questions to work assistant) |
| **Main Assistant Draft** | Your main assistant | Replies that require information across multiple domains |

You can send one of the drafts directly, edit then send, or write your own reply.

> The other side’s assistant cannot access your files directly. It can only see the message content you choose to send.

---

## Permission Model

### Two Layers of Protection

```
Layer 1: Global Authorization (folders selected in Security settings)
  └── Layer 2: Tag Permissions (each tag can access only a subset)
```

An assistant must satisfy both layers to access a file.

### Automatic Protection

The following locations are **never accessible**, with no manual setup needed:
- SSH keys (`~/.ssh/`)
- System password files (`/etc/shadow`, etc.)
- Environment variable files (`.env`, `.env.local`, etc.)

### Security Recommendations

- Use "Limited Scope" mode and authorize only necessary folders
- Review authorized folders regularly and remove what is no longer needed
- Delete operations are not permanent; files can be restored from Trash

---

## FAQ

### The assistant says "No permission to access". What should I do?

Go to Settings -> Security and check whether the target folder is authorized. If you are talking through a tag assistant, also check whether that tag includes the folder.

### I deleted a file by mistake. How do I restore it?

Tell the assistant "Undo the last delete" or "Restore that file." The assistant will find the record in operation history and restore it.

### What is the difference between the Main Assistant and other assistants?

The Main Assistant can access all folders you authorized. Other assistants can only access folders within their own tag scope. Use the Main Assistant for cross-domain tasks, and use tag assistants for focused tasks.

### In A2A, can the other side see my files?

No. The other side’s assistant can only see the reply content you choose to send. It cannot access your files directly.

### Where is the Trash?

Inside your authorized folders, there is a hidden directory: `.clawnet/trash/`. In Finder, press `Cmd + Shift + .` to show hidden files. Usually you do not need to open it manually; just ask the assistant to restore files for you.

### Will multiple assistants conflict if they work in the same folder?

No. Each assistant’s operation history is isolated per conversation, and each can only view and undo its own actions. The files are shared, but operation records are isolated.
