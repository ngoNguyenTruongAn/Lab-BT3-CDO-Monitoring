# CloudWatch CPU Alarm via SNS - Terraform Lab

## 1. Mục tiêu

Lab này triển khai hệ thống cảnh báo CPU cho EC2 bằng Terraform.

Khi CPU của EC2 vượt quá `80%` trong vòng `5 phút`, CloudWatch Alarm sẽ chuyển sang trạng thái `ALARM` và gửi cảnh báo đến email thông qua Amazon SNS.

Các mục tiêu chính:

* Tạo SNS Topic để nhận notification từ CloudWatch Alarm.
* Tạo Email Subscription cho SNS Topic.
* Tạo EC2 instance làm nguồn phát sinh CPU load.
* Tạo CloudWatch Alarm theo metric `CPUUtilization` của EC2.
* Kiểm tra email cảnh báo khi alarm chuyển sang trạng thái `ALARM`.
* Lưu evidence gồm ảnh apply Terraform, SNS subscription, CloudWatch Alarm và email alert.

---

## 2. Kiến trúc tổng quan

```txt
EC2 Instance
    |
    | CPUUtilization > 80% trong 5 phút
    v
CloudWatch Alarm
    |
    | Alarm state = ALARM
    v
SNS Topic
    |
    | Email Subscription
    v
Email Alert
```

Giải thích luồng hoạt động:

1. EC2 instance được tạo bằng Terraform.
2. EC2 chạy `user_data` để tạo CPU load.
3. CloudWatch theo dõi metric `CPUUtilization` của EC2.
4. Khi CPU vượt ngưỡng `80%`, CloudWatch Alarm chuyển sang trạng thái `ALARM`.
5. CloudWatch Alarm gửi notification đến SNS Topic.
6. SNS gửi email cảnh báo đến địa chỉ email đã subscribe.

---

## 3. Các file Terraform

Cấu trúc file trong lab:

```txt
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── terraform.tfvars
```

Mô tả từng file:

| File                       | Chức năng                                                                    |
| -------------------------- | ---------------------------------------------------------------------------- |
| `main.tf`                  | Khai báo SNS Topic, SNS Email Subscription, EC2 instance và CloudWatch Alarm |
| `variables.tf`             | Khai báo các biến như region, email nhận cảnh báo, instance type, subnet     |
| `outputs.tf`               | Xuất ra các thông tin quan trọng như SNS Topic ARN và EC2 Instance ID        |
| `terraform.tfvars.example` | File mẫu để cấu hình email cảnh báo                                          |
| `terraform.tfvars`         | File cấu hình thật, chứa email nhận cảnh báo                                 |

---

## 4. Cách triển khai

### 4.1 Khởi tạo Terraform

Chạy lệnh:

```bash
terraform init
```

Mục đích:

* Tải AWS provider.
* Khởi tạo Terraform working directory.
* Chuẩn bị môi trường để chạy plan/apply.

---

### 4.2 Tạo file `terraform.tfvars`

Tạo file `terraform.tfvars` từ file mẫu:

```bash
copy terraform.tfvars.example terraform.tfvars
```

Sau đó chỉnh nội dung:

```hcl
alert_email = "your-email@example.com"
```

Nếu muốn chỉ định subnet cụ thể, có thể thêm:

```hcl
subnet_id = "subnet-xxxxxxxx"
```

Nếu không cấu hình `subnet_id`, Terraform sẽ tự động lấy subnet đầu tiên trong default VPC.

---

### 4.3 Apply Terraform

Chạy lệnh:

```bash
terraform apply
```

Sau đó nhập:

```bash
yes
```

Terraform sẽ tạo các tài nguyên chính:

* SNS Topic.
* SNS Email Subscription.
* EC2 instance.
* CloudWatch Alarm.
* Notification action từ CloudWatch Alarm đến SNS Topic.

Sau khi apply thành công, cần kiểm tra email và bấm xác nhận subscription từ AWS SNS.

---

### 4.4 Confirm SNS Email Subscription

Sau khi Terraform tạo SNS Email Subscription, AWS SNS sẽ gửi một email xác nhận.

Cần mở email và bấm:

```txt
Confirm subscription
```

Sau khi xác nhận, trạng thái subscription sẽ chuyển sang:

```txt
Confirmed
```

Lưu ý: Nếu chưa confirm subscription, SNS Topic sẽ chưa gửi được email alert.

---

### 4.5 Kiểm tra CloudWatch Alarm

Vào AWS Console:

```txt
CloudWatch → Alarms → All alarms
```

Chọn alarm đã tạo.

Alarm sẽ theo dõi metric:

```txt
EC2 → Per-Instance Metrics → CPUUtilization
```

Điều kiện alarm:

```txt
CPUUtilization > 80%
Period: 5 minutes
Datapoints to alarm: 1 out of 1
```

Khi EC2 tạo CPU load đủ lâu, alarm sẽ chuyển sang trạng thái:

```txt
ALARM
```

---

### 4.6 Kiểm tra Email Alert

Khi CloudWatch Alarm chuyển sang trạng thái `ALARM`, SNS sẽ gửi email cảnh báo đến địa chỉ email đã subscribe.

Email alert thường chứa các thông tin:

* Alarm name.
* Alarm state.
* Metric name: `CPUUtilization`.
* Threshold: lớn hơn `80%`.
* EC2 Instance ID.
* Thời gian alarm được kích hoạt.

---

### 4.7 Kiểm tra Terraform Output

Chạy lệnh:

```bash
terraform output
```

Kết quả cần kiểm tra:

```txt
sns_topic_arn
ec2_instance_id
```

Mục đích:

* Xác nhận Terraform đã tạo SNS Topic thành công.
* Xác nhận EC2 instance đã được tạo và đang được CloudWatch Alarm theo dõi.

---

### 4.8 Xóa tài nguyên sau lab

Sau khi hoàn thành lab và đã lưu evidence, có thể xóa tài nguyên để tránh phát sinh chi phí:

```bash
terraform destroy
```

Nhập:

```bash
yes
```

---

## 5. Evidence

Các evidence đã chuẩn bị cho lab:

### Evidence 1: Terraform Apply thành công

Ảnh chụp màn hình lệnh:

```bash
terraform apply
```

Kết quả thể hiện Terraform đã tạo thành công các tài nguyên:

* SNS Topic.
* SNS Subscription.
* EC2 Instance.
* CloudWatch Alarm.

---
![apply](./Evidence/apply.jpg)


### Evidence 2: SNS Email Subscription đã Confirm

Ảnh chụp SNS Subscription có trạng thái:

```txt
Confirmed
```

Điều này chứng minh email đã được đăng ký thành công với SNS Topic và có thể nhận cảnh báo.

---
![Subscription](./Evidence/Subscription.jpg)
### Evidence 3: CloudWatch Alarm chuyển sang trạng thái ALARM

Ảnh chụp CloudWatch Alarm có trạng thái:

```txt
In alarm
```

Điều này chứng minh CPU của EC2 đã vượt ngưỡng được cấu hình và CloudWatch Alarm hoạt động đúng.

---
![CloudWatch Alarm](./Evidence/CloudWatch%20Alarm.jpg)
### Evidence 4: Email Alert từ SNS

Ảnh chụp email cảnh báo được gửi từ AWS SNS.

Email này chứng minh luồng notification hoạt động thành công:

```txt
CloudWatch Alarm → SNS Topic → Email Subscription
```
![Email Alert](./Evidence/Email%20Alert.jpg)
---

### Evidence 5: Terraform Output

Ảnh chụp kết quả:

```bash
terraform output
```

Kết quả hiển thị:

![Terraform Output](./Evidence/Terraform%20Output.jpg)

Điều này chứng minh Terraform đang quản lý đúng các tài nguyên được tạo trong lab.

---

## 6. Kết quả đạt được

Lab đã hoàn thành thành công các yêu cầu:

* Đã triển khai hạ tầng bằng Terraform.
* Đã tạo SNS Topic và Email Subscription.
* Đã tạo EC2 instance làm nguồn tạo CPU load.
* Đã tạo CloudWatch Alarm theo metric `CPUUtilization`.
* Đã cấu hình alarm gửi notification đến SNS Topic.
* Đã nhận được email cảnh báo khi CPU vượt quá `80%`.
* Đã lưu evidence đầy đủ cho quá trình triển khai và kiểm thử.

---

## 7. Ghi chú

* Lab này sử dụng metric mặc định `CPUUtilization` của EC2, nên không cần cài CloudWatch Agent.
* CloudWatch Agent chỉ cần thiết khi muốn thu thập thêm custom metrics như memory usage, disk usage hoặc application logs.
* SNS Email Subscription bắt buộc phải được confirm thủ công trước khi nhận alert.
* EC2 sử dụng `user_data` để tạo CPU load tự động, nên không cần SSH vào máy để chạy stress test thủ công.
* Sau khi hoàn thành lab, nên chạy `terraform destroy` để tránh phát sinh chi phí không cần thiết.
