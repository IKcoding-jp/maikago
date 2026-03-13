// gcloud OAuth トークンを Firebase Auth IDトークンに変換
const { execSync } = require('child_process');

const API_KEY = 'AIzaSyC-DgEFp7H0a6J9mFSE8_BUy1BNZ4ucgzU';

async function main() {
  try {
    // gcloud から Google OAuth ID トークンを取得
    const googleToken = execSync('gcloud auth print-identity-token', {
      encoding: 'utf-8',
    }).trim();

    if (!googleToken) {
      throw new Error('gcloud auth print-identity-token が空でした');
    }

    // Google ID トークンを Firebase Auth ID トークンに交換
    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          postBody: `id_token=${googleToken}&providerId=google.com`,
          requestUri: 'http://localhost',
          returnIdpCredential: true,
          returnSecureToken: true,
        }),
      }
    );

    const data = await response.json();
    if (data.idToken) {
      process.stdout.write(data.idToken);
    } else {
      process.stderr.write(JSON.stringify(data, null, 2));
      process.exit(1);
    }
  } catch (e) {
    process.stderr.write(e.message || String(e));
    process.exit(1);
  }
}

main();
