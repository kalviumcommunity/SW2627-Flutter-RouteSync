import assert from 'node:assert/strict';
import test, { after, before } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  addDoc,
} from 'firebase/firestore';
import {
  ref,
  uploadBytes,
} from 'firebase/storage';

const projectId = 'routesync-rules-test';
let testEnv;

const role = {
  dispatcher: 'dispatcher-1',
  executiveA: 'executive-a',
  executiveB: 'executive-b',
  inactive: 'inactive-user',
};

function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function storage(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

async function seed() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(doc(firestore, 'users', role.dispatcher), {
        role: 'DISPATCHER',
        active: true,
      }),
      setDoc(doc(firestore, 'users', role.executiveA), {
        role: 'EXECUTIVE',
        active: true,
      }),
      setDoc(doc(firestore, 'users', role.executiveB), {
        role: 'EXECUTIVE',
        active: true,
      }),
      setDoc(doc(firestore, 'users', role.inactive), {
        role: 'EXECUTIVE',
        active: false,
      }),
      setDoc(doc(firestore, 'deliveries', 'delivery-a'), {
        assignedExecutiveId: role.executiveA,
        status: 'ASSIGNED',
      }),
      setDoc(doc(firestore, 'deliveries', 'delivery-b'), {
        assignedExecutiveId: role.executiveB,
        status: 'ASSIGNED',
      }),
      setDoc(doc(firestore, 'deliveries', 'delivery-transition'), {
        assignedExecutiveId: role.executiveA,
        status: 'ASSIGNED',
      }),
      setDoc(doc(firestore, 'deliveries', 'delivery-dispatcher'), {
        assignedExecutiveId: role.executiveA,
        status: 'ASSIGNED',
      }),
    ]);
  });
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
  await seed();
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test('dispatcher reads deliveries and can change assignment only', async () => {
  const firestore = db(role.dispatcher);
  await assertSucceeds(
    getDoc(doc(firestore, 'deliveries', 'delivery-dispatcher')),
  );
  await assertSucceeds(
    updateDoc(doc(firestore, 'deliveries', 'delivery-dispatcher'), {
      assignedExecutiveId: role.executiveB,
    }),
  );
  await assertFails(
    updateDoc(doc(firestore, 'deliveries', 'delivery-dispatcher'), {
      status: 'DELIVERED',
    }),
  );
});

test('dispatcher can assign only active executives', async () => {
  const delivery = doc(db(role.dispatcher), 'deliveries', 'delivery-dispatcher');
  await assertFails(
    updateDoc(delivery, { assignedExecutiveId: role.inactive }),
  );
  await assertFails(
    updateDoc(delivery, { assignedExecutiveId: 'missing-executive' }),
  );
});

test('inactive users cannot access deliveries or Storage', async () => {
  await assertFails(
    getDoc(doc(db(role.inactive), 'deliveries', 'delivery-a')),
  );
  await assertFails(
    uploadBytes(
      ref(storage(role.inactive), 'deliveries/delivery-a/inactive.jpg'),
      new Uint8Array([0xff, 0xd8, 0xff, 0xd9]),
      { contentType: 'image/jpeg' },
    ),
  );
});

test('executives only read their assigned deliveries', async () => {
  await assertSucceeds(
    getDoc(doc(db(role.executiveA), 'deliveries', 'delivery-a')),
  );
  await assertFails(
    getDoc(doc(db(role.executiveA), 'deliveries', 'delivery-b')),
  );
});

test('users cannot change their own role or active flag', async () => {
  const user = doc(db(role.executiveA), 'users', role.executiveA);
  await assertFails(updateDoc(user, { role: 'DISPATCHER' }));
  await assertFails(updateDoc(user, { active: false }));
});

test('executives can only make valid forward delivery transitions', async () => {
  const delivery = doc(
    db(role.executiveA),
    'deliveries',
    'delivery-transition',
  );
  await assertSucceeds(updateDoc(delivery, { status: 'PICKED UP' }));
  await assertSucceeds(updateDoc(delivery, { status: 'OUT FOR DELIVERY' }));
  await assertFails(updateDoc(delivery, { status: 'ASSIGNED' }));
});

test('escalations enforce assignment and dispatcher resolution', async () => {
  const executive = db(role.executiveA);
  const reference = await assertSucceeds(
    addDoc(collection(executive, 'escalations'), {
      deliveryId: 'delivery-a',
      raisedBy: role.executiveA,
      reason: 'Customer issue',
      description: 'Needs review',
      priority: 'HIGH',
      status: 'OPEN',
    }),
  );
  await assertFails(
    addDoc(collection(db(role.executiveB), 'escalations'), {
      deliveryId: 'delivery-a',
      raisedBy: role.executiveB,
      reason: 'Unauthorized',
      description: 'Should fail',
      priority: 'LOW',
      status: 'OPEN',
    }),
  );
  await assertSucceeds(
    updateDoc(
      doc(db(role.dispatcher), 'escalations', reference.id),
      { status: 'RESOLVED' },
    ),
  );
});

test('proof URL updates and Storage writes are assignment-bound', async () => {
  await assertSucceeds(
    updateDoc(doc(db(role.executiveA), 'deliveries', 'delivery-a'), {
      proofImageUrl: 'https://example.test/proof.jpg',
    }),
  );
  await assertFails(
    updateDoc(doc(db(role.executiveB), 'deliveries', 'delivery-a'), {
      proofImageUrl: 'https://example.test/unauthorized.jpg',
    }),
  );

  const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
  await assertSucceeds(
    uploadBytes(
      ref(storage(role.executiveA), 'deliveries/delivery-a/proof.jpg'),
      bytes,
      { contentType: 'image/jpeg' },
    ),
  );
  await assertFails(
    uploadBytes(
      ref(storage(role.executiveB), 'deliveries/delivery-a/other.jpg'),
      bytes,
      { contentType: 'image/jpeg' },
    ),
  );
  await assertFails(
    uploadBytes(
      ref(storage(role.dispatcher), 'deliveries/delivery-a/dispatcher.jpg'),
      bytes,
      { contentType: 'image/jpeg' },
    ),
  );
});
