#!/usr/bin/env bash
# Drives CPU load on the Lab3 Auto Scaling group over SSM so the target tracking
# policy scales out. Load is applied on the instances rather than over HTTP because
# nginx serving a static file uses almost no CPU, so an HTTP flood would saturate the
# generator long before it moved the metric the policy watches.
set -euo pipefail

PROFILE="${AWS_PROFILE:-academy}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ASG_NAME="${ASG_NAME:-lab3-asg}"
DURATION="${DURATION:-420}"
PIDFILE="/tmp/lab3-load.pids"

usage() {
  cat <<USAGE
Usage: $0 [start|stop|status]

  start   Start one busy loop per vCPU on every InService instance (default).
  stop    Kill the busy loops so the group can scale back in.
  status  Show current group capacity and instance states.

Environment:
  ASG_NAME    Auto Scaling group name   (default: lab3-asg)
  DURATION    Seconds of load           (default: 420)
  AWS_PROFILE AWS CLI profile           (default: academy)
USAGE
}

aws_() {
  aws --profile "$PROFILE" --region "$REGION" "$@"
}

instance_ids() {
  aws_ autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId' \
    --output text
}

send() {
  local params_file="$1" ids="$2"
  # shellcheck disable=SC2086
  aws_ ssm send-command \
    --document-name "AWS-RunShellScript" \
    --instance-ids $ids \
    --parameters "file://$params_file" \
    --comment "lab3 load test" \
    --query 'Command.CommandId' --output text
}

cmd_start() {
  local ids
  ids="$(instance_ids)"
  [ -n "$ids" ] || { echo "No InService instances in $ASG_NAME." >&2; exit 1; }
  echo "Loading: $ids"

  local params
  params="$(mktemp)"
  trap 'rm -f "$params"' RETURN

  cat > "$params" <<JSON
{
  "commands": [
    "rm -f $PIDFILE",
    "for i in \$(seq 1 \$(nproc)); do setsid sh -c 'echo \$\$ >> $PIDFILE; exec timeout $DURATION sh -c \"while :; do :; done\"' </dev/null >/dev/null 2>&1 & done",
    "sleep 1",
    "echo started \$(wc -l < $PIDFILE) busy loops for ${DURATION}s"
  ]
}
JSON

  echo "CommandId: $(send "$params" "$ids")"
  cat <<NEXT

Load runs for ${DURATION}s. The CloudWatch alarm needs ~3 minutes of sustained CPU
before it fires. Watch with:

  watch -n 15 '$0 status'
NEXT
}

# Each busy loop records its own PID, and setsid makes that PID a process group leader,
# so stopping is "kill the recorded process groups" rather than a pattern match against
# command lines. Pattern matching here is fragile: pkill -f can match the very shell
# that invoked it.
cmd_stop() {
  local ids
  ids="$(instance_ids)"
  [ -n "$ids" ] || { echo "No InService instances in $ASG_NAME." >&2; exit 1; }

  local params
  params="$(mktemp)"
  trap 'rm -f "$params"' RETURN

  cat > "$params" <<JSON
{
  "commands": [
    "while read p; do kill -TERM -- -\$p 2>/dev/null || true; done < $PIDFILE 2>/dev/null || true",
    "rm -f $PIDFILE",
    "echo stopped"
  ]
}
JSON

  echo "CommandId: $(send "$params" "$ids")"
}

cmd_status() {
  aws_ autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].{Desired:DesiredCapacity,Min:MinSize,Max:MaxSize}' \
    --output table
  aws_ autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].Instances[].[InstanceId,LifecycleState,HealthStatus,AvailabilityZone]' \
    --output table
}

case "${1:-start}" in
  start)  cmd_start  ;;
  stop)   cmd_stop   ;;
  status) cmd_status ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac
