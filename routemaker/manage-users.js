#!/usr/bin/env node

const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const readline = require('readline');

const db = new Database('./data/routemaker.db');

const colors = [
  '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8',
  '#F7DC6F', '#BB8FCE', '#85C1E2', '#F8B739', '#52B788',
  '#E74C3C', '#3498DB', '#2ECC71', '#F39C12', '#9B59B6'
];

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function questionHidden(query) {
  // Simple version - just use regular readline (password will be visible)
  // For production, this would use a proper password input library
  console.log('\n⚠️  Note: Password will be visible on screen');
  return await question(query);
}

async function createUser(cliUsername = null, cliPassword = null) {
  console.log('\n=== RouteMaker - Create User ===\n');
  
  // Support non-interactive mode via CLI arguments
  const username = cliUsername || await question('Username: ');
  
  if (!username || username.length < 3) {
    console.error('Error: Username must be at least 3 characters');
    rl.close();
    process.exit(1);
  }

  // Check if user exists
  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
  if (existing) {
    console.error('Error: User already exists');
    rl.close();
    process.exit(1);
  }

  let password;
  if (cliPassword) {
    // Non-interactive mode: use provided password
    password = cliPassword;
  } else {
    // Interactive mode: prompt for password
    password = await questionHidden('Password: ');
    
    if (!password || password.length < 6) {
      console.error('\nError: Password must be at least 6 characters');
      rl.close();
      process.exit(1);
    }

    const passwordConfirm = await questionHidden('Confirm password: ');
    
    if (password !== passwordConfirm) {
      console.error('\nError: Passwords do not match');
      rl.close();
      process.exit(1);
    }
  }
  
  if (!password || password.length < 6) {
    console.error('Error: Password must be at least 6 characters');
    rl.close();
    process.exit(1);
  }

  // Always use random color
  const color = colors[Math.floor(Math.random() * colors.length)];

  // Hash password and create user
  const hashedPassword = bcrypt.hashSync(password, 10);
  
  try {
    db.prepare('INSERT INTO users (username, password, color) VALUES (?, ?, ?)')
      .run(username, hashedPassword, color);
    
    console.log(`\n✓ User '${username}' created successfully with color ${color}`);
  } catch (error) {
    console.error('\nError creating user:', error.message);
    process.exit(1);
  }
  
  rl.close();
  db.close();
}

async function listUsers() {
  console.log('\n=== RouteMaker - Users ===\n');
  
  const users = db.prepare('SELECT id, username, color, created_at FROM users ORDER BY created_at').all();
  
  if (users.length === 0) {
    console.log('No users found.');
  } else {
    users.forEach(user => {
      console.log(`  ${user.id}. ${user.username} (${user.color}) - created ${user.created_at}`);
    });
  }
  
  rl.close();
  db.close();
}

async function deleteUser() {
  console.log('\n=== RouteMaker - Delete User ===\n');
  
  const username = await question('Username to delete: ');
  
  const user = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
  
  if (!user) {
    console.error('Error: User not found');
    rl.close();
    process.exit(1);
  }

  const confirm = await question(`Are you sure you want to delete '${username}'? (yes/no): `);
  
  if (confirm.toLowerCase() !== 'yes') {
    console.log('Cancelled.');
    rl.close();
    process.exit(0);
  }

  // Delete user and their routes
  db.prepare('DELETE FROM routes WHERE user_id = ?').run(user.id);
  db.prepare('DELETE FROM users WHERE id = ?').run(user.id);
  
  console.log(`✓ User '${username}' and their routes deleted successfully`);
  
  rl.close();
  db.close();
}

async function main() {
  const command = process.argv[2];
  const username = process.argv[3];
  const password = process.argv[4];
  
  switch (command) {
    case 'create':
      await createUser(username, password);
      break;
    case 'list':
      await listUsers();
      break;
    case 'delete':
      await deleteUser();
      break;
    default:
      console.log('RouteMaker User Management');
      console.log('');
      console.log('Usage:');
      console.log('  node manage-users.js create [username] [password] - Create a new user');
      console.log('  node manage-users.js list                         - List all users');
      console.log('  node manage-users.js delete                       - Delete a user');
      console.log('');
      console.log('Examples:');
      console.log('  Interactive:     node manage-users.js create');
      console.log('  Non-interactive: node manage-users.js create john secret123');
      process.exit(1);
  }
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
