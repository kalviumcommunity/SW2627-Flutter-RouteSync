import assert from 'node:assert/strict';
import test, { after, before } from 'node:test';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { initializeApp, deleteApp } from 'firebase/app';
import {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import {
  collection,
  connectFirestoreEmulator,
  disableNetwork,
  doc,
  enableNetwork,
  getDoc,
  getDocFromCache,
  getDocs,
  getFirestore,
  onSnapshot,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import {
  connectStorageEmulator,
  getStorage,
  ref,
  uploadBytes,
} from 'firebase/storage';

const projectId = 'routesync-integration-test';
const firebaseConfig = {
  apiKey: 'demo-api-key',
  authDomain: `${projectId}.firebaseapp.com`,
  projectId,
  storageBucket: `${projectId}.firebasestorage.app`,
};
const users = {
  dispatcher: {
    email: 'dispatcher@example.com',
    password: 'password123',
    role: 'DISPATCHER',
  },
  executive: {
    email: 'executive@example.com',
    password: 'password123',
    role: 'EXECUTIVE',
  },
};

let testEnv;
let app;
let auth;
let firestore;
let storage;
let executiveApp;
let executiveAuth;
let executiveFirestore;
let executiveStorage;
let dispatcherUid;
let executiveUid;

async function signInAs(account, targetAuth = auth) {
  await signOut(targetAuth);
  await signInWithEmailAndPassword(
    targetAuth,
    account.email,
    account.password,
  );
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: await import('node:fs/promises').then((fs) =>
        fs.readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
      ),
    },
    storage: {
      host: '127.0.0.1',
      port: 9199,
      rules: await import('node:fs/promises').then((fs) =>
        fs.readFile(new URL('../storage.rules', import.meta.url), 'utf8'),
      ),
    },
  });

  app = initializeApp(firebaseConfig, 'integration-client');
  auth = getAuth(app);
  firestore = getFirestore(app);
  storage = getStorage(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(firestore, '127.0.0.1', 8080);
  connectStorageEmulator(storage, '127.0.0.1', 9199);
  executiveApp = initializeApp(firebaseConfig, 'integration-executive-client');
  executiveAuth = getAuth(executiveApp);
  executiveFirestore = getFirestore(executiveApp);
  executiveStorage = getStorage(executiveApp);
  connectAuthEmulator(executiveAuth, 'http://127.0.0.1:9099', {
    disableWarnings: true,
  });
  connectFirestoreEmulator(executiveFirestore, '127.0.0.1', 8080);
  connectStorageEmulator(executiveStorage, '127.0.0.1', 9199);

  const dispatcher = await createUserWithEmailAndPassword(
    auth,
    users.dispatcher.email,
    users.dispatcher.password,
  );
  dispatcherUid = dispatcher.user.uid;
  await signOut(auth);
  const executive = await createUserWithEmailAndPassword(
    auth,
    users.executive.email,
    users.executive.password,
  );
  executiveUid = executive.user.uid;

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await Promise.all([
      setDoc(doc(adminDb, 'users', dispatcherUid), {
        role: users.dispatcher.role,
        active: true,
        name: 'Dispatcher',
        email: users.dispatcher.email,
      }),
      setDoc(doc(adminDb, 'users', executiveUid), {
        role: users.executive.role,
        active: true,
        name: 'Executive',
        email: users.executive.email,
      }),
      setDoc(doc(adminDb, 'deliveries', 'delivery-1'), {
        assignedExecutiveId: executiveUid,
        status: 'ASSIGNED',
        orderId: 'RS-001',
      }),
    ]);
  });
});

after(async () => {
  if (auth) await signOut(auth);
  if (executiveAuth) await signOut(executiveAuth);
  if (app) await deleteApp(app);
  if (executiveApp) await deleteApp(executiveApp);
  if (testEnv) await testEnv.cleanup();
});

test('authenticated sign-in and profile role validation', async () => {
  await signInAs(users.executive);
  assert.equal(auth.currentUser?.uid, executiveUid);
  const profile = await getDoc(doc(firestore, 'users', executiveUid));
  assert.equal(profile.data()?.role, 'EXECUTIVE');
  assert.equal(profile.data()?.active, true);
});

test('executive retrieval and valid/invalid status updates', async () => {
  await signInAs(users.executive);
  const assigned = await getDocs(
    query(
      collection(firestore, 'deliveries'),
      where('assignedExecutiveId', '==', executiveUid),
    ),
  );
  assert.equal(assigned.size, 1);
  const delivery = doc(firestore, 'deliveries', 'delivery-1');
  await updateDoc(delivery, { status: 'PICKED UP' });
  await updateDoc(delivery, { status: 'OUT FOR DELIVERY' });
  await assert.rejects(
    updateDoc(delivery, { status: 'ASSIGNED' }),
  );
});

test('dispatcher receives real-time delivery changes', async () => {
  await signInAs(users.dispatcher);
  const changes = new Promise((resolve, reject) => {
    const unsubscribe = onSnapshot(
      collection(firestore, 'deliveries'),
      (snapshot) => {
        if (snapshot.docs.some((item) => item.data().status === 'DELIVERED')) {
          unsubscribe();
          resolve();
        }
      },
      reject,
    );
  });
  await signInAs(users.executive, executiveAuth);
  await updateDoc(doc(executiveFirestore, 'deliveries', 'delivery-1'), {
    status: 'DELIVERED',
  });
  await changes;
});

test('cached delivery documents remain readable while Firestore is offline', async () => {
  await signInAs(users.executive, executiveAuth);
  const delivery = doc(executiveFirestore, 'deliveries', 'delivery-1');
  await getDoc(delivery);
  await disableNetwork(executiveFirestore);
  try {
    const cached = await getDocFromCache(delivery);
    assert.equal(cached.exists(), true);
    assert.equal(cached.data()?.status, 'DELIVERED');
  } finally {
    await enableNetwork(executiveFirestore);
  }
});

test('escalation creation and dispatcher resolution', async () => {
  await signInAs(users.executive);
  const escalation = doc(collection(firestore, 'escalations'));
  await setDoc(escalation, {
    deliveryId: 'delivery-1',
    raisedBy: executiveUid,
    reason: 'Customer issue',
    description: 'Needs review',
    priority: 'HIGH',
    status: 'OPEN',
  });
  await signInAs(users.dispatcher);
  await updateDoc(escalation, { status: 'RESOLVED' });
  assert.equal((await getDoc(escalation)).data()?.status, 'RESOLVED');
});

test('assigned executive can upload proof to Storage', async () => {
  await signInAs(users.executive);
  const proof = ref(storage, `deliveries/delivery-1/proof-${executiveUid}.jpg`);
  await uploadBytes(proof, new Uint8Array([0xff, 0xd8, 0xff, 0xd9]), {
    contentType: 'image/jpeg',
  });
});
