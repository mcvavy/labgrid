# RabbitMQ (Labgrid)

Deploys a **`RabbitmqCluster`** CR named `rabbitmq` in `rabbitmq-system` (ApplicationSet namespace `{{path.basename}}-system`).

Requires the **rabbitmq-cluster-operator** Helm release in [`Base/Operators`](../../../Base/Operators) (CloudPirates chart `0.5.5`).

## HA

Per [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/using-operator) and [quorum queues](https://www.rabbitmq.com/docs/quorum-queues) / [vhost DQT](https://www.rabbitmq.com/docs/vhosts#node-wide-default-queue-type-node-wide-dqt):

- `replicas: 3` (odd count; even is discouraged)
- `rabbitmq.additionalConfig`: `default_queue_type = quorum` (node-wide DQT for undeclared type)
- `quorum_queue.property_equivalence.relaxed_checks_on_redeclaration = true` eases classic→quorum redeclaration during cutover
- Apps (Wolverine) call `.UseQuorumQueues()` so application queues declare `x-queue-type=quorum` explicitly

Existing classic queues are **not** converted; queue type is immutable. Fresh broker / recreated queues get quorum.

## Credentials

ExternalSecret `rabbitmq-credentials` templates the operator secret shape from AKV:

- `platform-rabbitmq-password` → `password` + `default_user.conf`
- `platform-rabbitmq-erlang-cookie` → `.erlang.cookie`
- username fixed to `admin`

Apps continue to use `amqp://admin:${RABBITMQ_PASSWORD}@rabbitmq.rabbitmq-system.svc.cluster.local:5672`.

Operator also maintains a separate `rabbitmq-erlang-cookie` Secret for the StatefulSet cookie mount.

## Operator quirks

- Set `rabbitmqCluster.image` explicitly (operator chart leaves `ENABLE_WEBHOOKS=false`).
- Keep memory request == limit to avoid operator `NoWarnings` false.
- Client Service stays `rabbitmq` (5672/15672/15692); headless `rabbitmq-nodes`; STS `rabbitmq-server`; PVCs `persistence-rabbitmq-server-{0,1,2}`.

## Cutover

1. Deploy/sync the operator; confirm `kubectl get crd rabbitmqclusters.rabbitmq.com`.
2. Optionally export definitions from the old standalone broker if topology must survive (classic queues will not become quorum).
3. Uninstall the old CloudPirates `rabbitmq` 0.21.4 release so Service name `rabbitmq` is free.
4. Sync this chart; wait for `AllReplicasReady` / `ClusterAvailable` and healthy `quorumStatus`.
5. Deploy apps with Wolverine `.UseQuorumQueues()` so AutoProvision creates quorum queues.
6. Confirm apps reconnect; delete leftover standalone PVCs when safe.
