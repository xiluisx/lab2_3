# Escalables — Lab2 & Lab3

Lab2 serves `https://lab2.luisv.dev` from an Application Load Balancer across two
fixed EC2 instances. Lab3 serves `https://lab3.luisv.dev` from an ALB across an EC2
Auto Scaling group. Both serve a page that identifies the instance answering the
request, by ID and by background color.

## Cost — read this first

Roughly **$0.05 per hour per lab**; about **$2.40 per day** with both running.
Destroy them when you are not demonstrating:

```bash
terraform -chdir=lab2 destroy
terraform -chdir=lab3 destroy
```

Then delete the four Cloudflare CNAMEs.

## Prerequisites

```bash
export AWS_PROFILE=academy
export AWS_DEFAULT_REGION=us-east-1
aws sts get-caller-identity
```

The AWS Academy Learner Lab session expires roughly every four hours. `Your session
has expired` from any command means restart the lab in the Academy console. Terraform
state is unaffected — re-run the command.

The instances attach the pre-provisioned `LabInstanceProfile`. Terraform creates no
IAM resources, because the Learner Lab denies `iam:CreateRole`.

## Deploy

Each lab applies in two phases, because the ACM validation record is added by hand.

```bash
cd lab2                                                  # or lab3
terraform init
terraform apply -target=module.acm.aws_acm_certificate.this
terraform output -json validation_record
```

Create that CNAME in the `luisv.dev` Cloudflare zone, **DNS only (grey cloud)**.
ACM cannot validate through the Cloudflare proxy; an orange cloud here will hang the
next step until it times out.

```bash
terraform apply
terraform output -raw alb_dns_name
```

Create a `lab2` (or `lab3`) CNAME pointing at that hostname, **DNS only**.

Keep the grey cloud until you have confirmed rotation. The Cloudflare proxy caches
responses and pools upstream connections, either of which can hide the load balancing
and make a working setup look broken. Once it works, switching to proxied requires SSL
mode **Full (strict)**; the ACM certificate is publicly trusted, so strict validation
passes.

## Verify

```bash
terraform -chdir=lab2 output -raw target_group_arn | \
  xargs -I{} aws elbv2 describe-target-health --target-group-arn {} \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output table
```

Both targets should read `healthy`, two to three minutes after apply.

```bash
for i in $(seq 1 12); do
  curl -s https://lab2.luisv.dev/ | grep -o 'i-[0-9a-f]\{8,\}' | head -1
done | sort | uniq -c
```

Both instance IDs should appear, roughly balanced. In a browser the page reloads every
two seconds and changes color as different instances answer — that is the deliverable.

The HTTP redirect:

```bash
curl -sI http://lab2.luisv.dev/ | head -3
```

Expected: `301` with a `location: https://...` header.

## Lab3 scale-out demo

```bash
./scripts/load-test.sh status
./scripts/load-test.sh start
watch -n 15 './scripts/load-test.sh status'
./scripts/load-test.sh stop
```

Desired capacity should rise above 2 within three to five minutes of sustained load.
Scale-in afterwards is deliberately slow — roughly fifteen minutes.

Load is applied on the instances over SSM rather than over HTTP, because nginx serving
a static file uses almost no CPU; an HTTP flood would saturate the generator long
before it moved the metric the scaling policy watches.

If capacity never moves, check the alarm:

```bash
aws cloudwatch describe-alarms --alarm-name-prefix TargetTracking-lab3-asg \
  --query 'MetricAlarms[].[AlarmName,StateValue]' --output table
```

## Shell access

No SSH, no key pair, port 22 never opened. Use Session Manager:

```bash
aws ssm start-session --target <instance-id>
```

## Layout

| Path | Contents |
|---|---|
| `modules/network` | VPC, IGW, two public subnets, route table |
| `modules/webserver` | Security groups, AMI lookup, page template |
| `modules/acm` | Certificate and DNS validation |
| `modules/alb` | Load balancer, target group, listeners |
| `lab2` | Two fixed instances |
| `lab3` | Launch template, ASG, CPU target tracking |
| `scripts/load-test.sh` | SSM-driven CPU load for the scale-out demo |

Design notes are in `docs/superpowers/specs/`, the build plan in `docs/superpowers/plans/`.

## Troubleshooting

| Symptom | Cause |
|---|---|
| Certificate stuck `PENDING_VALIDATION` | Validation CNAME proxied, or not added |
| 502 from the ALB | `web-sg` missing the ALB rule, or nginx not started |
| Targets `unhealthy` | `/health` missing, or health check path wrong |
| Page never changes instance | Stickiness enabled, or a cache in the way |
| ASG never scales out | Load applied over HTTP instead of on-instance |
| `Your session has expired` | Learner Lab session lapsed; restart it |
