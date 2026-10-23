# Executive Integration Contract

The Executive UI currently depends on `ExecutiveRepository` in `lib/screens/executive/executive_repository.dart`. Teammate 3 should provide an authenticated implementation and inject it into `ExecutiveHome`.

Required operations:

- `load`: obtain the authenticated user profile and only that user's assigned deliveries. Prefer a Firestore `snapshots()` stream or an equivalent subscription so status changes are reflected without duplicate listeners. The current UI accepts a one-shot `Future`; change the seam to a stream or add a subscription adapter when the shared service is available.
- `updateStatus`: atomically validate the server-side transition, write `status`, `failureReason`, `notes`, and `updatedAt` using a server timestamp, and return the persisted delivery. Authorization must come from Firebase Auth and Security Rules, never a client-supplied executive ID.
- Failed delivery: permit only `OUT FOR DELIVERY` to `FAILED`; persist one of the exact `failureReasons`, optional notes, and server `updatedAt`.
- `createEscalation`: persist `deliveryId`, authenticated `raisedBy`, reason, description, `LOW`/`MEDIUM`/`HIGH` priority, `OPEN` status, and server `createdAt` in `escalations`.
- `uploadProof`: accept a selected/captured image, upload it to Firebase Storage under an authorized delivery path, obtain the download URL, and atomically persist `proofImageUrl`. Do not report success before both operations finish. Add `image_picker` only when Storage configuration is ready.
- `signOut`: delegate to the shared Auth service and return through the established auth/role router.
- Notifications: provide a real notification model/service or keep the current unsupported state. Do not create local or fabricated notification records.

Required integration inputs are Firebase initialization/options, Auth service identity/profile APIs, Firestore collection/query names and timestamp conversion, Storage rules/path, notification schema/service, and Security Rules that enforce executive ownership and allowed writes.
