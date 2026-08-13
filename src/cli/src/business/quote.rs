#![allow(dead_code)]
use anyhow::{Result, anyhow, bail};

// ── 报价模型 ──

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum PersonnelLevel {
    Chief,
    Senior,
    Advanced,
    Mid,
    Junior,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ApprovalType {
    Standard,
    Major,
    Discount,
}

pub struct ServiceItem {
    pub name: &'static str,
    pub hours: f64,
    pub level: PersonnelLevel,
}

pub struct Quotation {
    pub items: Vec<ServiceItem>,
    pub premium_rate: f64,
}

const ENTERPRISE_RATES: [(PersonnelLevel, f64); 2] = [
    (PersonnelLevel::Chief, 2000.0),
    (PersonnelLevel::Advanced, 1000.0),
];

const DISCOUNT_RULES: [(f64, f64); 2] = [(20.0, 0.15), (10.0, 0.10)];

const RETROSPECTIVE_EXAMPLE: &str = "retrospective";
const RETROSPECTIVE_PROJECT: &str = "议事决议数据需求点";
const RETROSPECTIVE_CLIENT: &str = "量潮科技（内部项目）";
const RETROSPECTIVE_NOTE: &str = "成本法约0.5万元；市场法约1.2万元；内部价=市场价×7折≈0.8万元";

pub struct Summary {
    pub total_hours: f64,
    pub base_total: f64,
    pub premium_rate: f64,
    pub premium_amount: f64,
    pub discount_rate: f64,
    pub discount_amount: f64,
    pub total: f64,
    pub approval_type: ApprovalType,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ProductQuoteItem {
    pub name: String,
    pub unit_price: f64,
    pub quantity: f64,
    pub discount: f64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ProductQuotation {
    pub project: String,
    pub client: String,
    pub items: Vec<ProductQuoteItem>,
    pub note: Option<String>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ProductQuoteLineSummary {
    pub name: String,
    pub unit_price: f64,
    pub quantity: f64,
    pub discount: f64,
    pub subtotal: f64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ProductQuoteSummary {
    pub line_count: usize,
    pub lines: Vec<ProductQuoteLineSummary>,
    pub total_amount: f64,
}

fn unit_price(level: PersonnelLevel) -> Option<f64> {
    ENTERPRISE_RATES
        .iter()
        .find(|(l, _)| *l == level)
        .map(|(_, p)| *p)
}

impl Quotation {
    pub fn total_hours(&self) -> f64 {
        self.items.iter().map(|i| i.hours).sum()
    }

    pub fn base_total(&self) -> Option<f64> {
        let mut total = 0.0;
        for item in &self.items {
            total += unit_price(item.level)? * item.hours;
        }
        Some(total)
    }

    pub fn premium_amount(&self) -> Option<f64> {
        Some(self.base_total()? * self.premium_rate)
    }

    pub fn discount_rate(&self) -> f64 {
        let hours = self.total_hours();
        for (threshold, rate) in DISCOUNT_RULES {
            if hours >= threshold {
                return rate;
            }
        }
        0.0
    }

    pub fn discount_amount(&self) -> Option<f64> {
        Some(self.base_total()? * self.discount_rate())
    }

    pub fn total(&self) -> Option<f64> {
        let base = self.base_total()?;
        Some((base + base * self.premium_rate) * (1.0 - self.discount_rate()))
    }

    pub fn approval_type(&self) -> ApprovalType {
        if self.premium_rate > 0.0 {
            return ApprovalType::Major;
        }
        if self.discount_rate() > 0.0 {
            return ApprovalType::Discount;
        }
        ApprovalType::Standard
    }

    pub fn summary(&self) -> Summary {
        Summary {
            total_hours: self.total_hours(),
            base_total: self.base_total().unwrap_or(0.0),
            premium_rate: self.premium_rate,
            premium_amount: self.premium_amount().unwrap_or(0.0),
            discount_rate: self.discount_rate(),
            discount_amount: self.discount_amount().unwrap_or(0.0),
            total: self.total().unwrap_or(0.0),
            approval_type: self.approval_type(),
        }
    }
}

impl ProductQuoteItem {
    pub fn subtotal(&self) -> f64 {
        self.unit_price * self.quantity * self.discount
    }
}

impl ProductQuotation {
    pub fn summary(&self) -> Result<ProductQuoteSummary> {
        if self.items.is_empty() {
            bail!("product quotation must include at least one item");
        }

        let mut lines = Vec::with_capacity(self.items.len());
        let mut total_amount = 0.0;

        for item in &self.items {
            validate_product_quote_item(item)?;
            let subtotal = item.subtotal();
            total_amount += subtotal;
            lines.push(ProductQuoteLineSummary {
                name: item.name.clone(),
                unit_price: item.unit_price,
                quantity: item.quantity,
                discount: item.discount,
                subtotal,
            });
        }

        Ok(ProductQuoteSummary {
            line_count: lines.len(),
            lines,
            total_amount,
        })
    }
}

fn validate_product_quote_item(item: &ProductQuoteItem) -> Result<()> {
    if item.name.trim().is_empty() {
        bail!("item name cannot be empty");
    }
    if !item.unit_price.is_finite() {
        bail!("unit_price must be finite");
    }
    if !item.quantity.is_finite() {
        bail!("quantity must be finite");
    }
    if !item.discount.is_finite() {
        bail!("discount must be finite");
    }
    if item.unit_price < 0.0 {
        bail!("unit_price cannot be negative");
    }
    if item.quantity < 0.0 {
        bail!("quantity cannot be negative");
    }
    if !(0.0..=1.0).contains(&item.discount) {
        bail!("discount must be between 0 and 1");
    }
    Ok(())
}

fn parse_required_text(value: &str, field_name: &str) -> Result<String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        bail!("{field_name} cannot be empty");
    }
    Ok(trimmed.to_string())
}

fn parse_number(value: &str, field_name: &str) -> Result<f64> {
    let number = value
        .parse::<f64>()
        .map_err(|_| anyhow!("{field_name} must be a number"))?;
    if !number.is_finite() {
        bail!("{field_name} must be finite");
    }
    Ok(number)
}

pub fn parse_product_quote_item(raw: &str) -> Result<ProductQuoteItem> {
    let parts = raw.split('|').map(str::trim).collect::<Vec<_>>();
    if parts.len() != 4 {
        bail!("item must use format: name|unit_price|quantity|discount");
    }

    let item = ProductQuoteItem {
        name: parse_required_text(parts[0], "item name")?,
        unit_price: parse_number(parts[1], "unit_price")?,
        quantity: parse_number(parts[2], "quantity")?,
        discount: parse_number(parts[3], "discount")?,
    };

    validate_product_quote_item(&item)?;
    Ok(item)
}

pub fn retrospective_product_quotation() -> ProductQuotation {
    ProductQuotation {
        project: RETROSPECTIVE_PROJECT.to_string(),
        client: RETROSPECTIVE_CLIENT.to_string(),
        items: vec![
            ProductQuoteItem {
                name: "议事决议数据-决议档案".to_string(),
                unit_price: 0.4,
                quantity: 1.0,
                discount: 1.0,
            },
            ProductQuoteItem {
                name: "议事决议数据-治理视图".to_string(),
                unit_price: 0.2,
                quantity: 1.0,
                discount: 1.0,
            },
            ProductQuoteItem {
                name: "周会决议汇总与历史批量整理".to_string(),
                unit_price: 0.2,
                quantity: 1.0,
                discount: 1.0,
            },
        ],
        note: Some(RETROSPECTIVE_NOTE.to_string()),
    }
}

// ── CLI 命令 ──

#[derive(clap::Args, Clone)]
pub struct QuoteArgs {
    /// 服务时长（小时）
    #[arg(long, allow_hyphen_values = true)]
    pub hours: Option<f64>,

    /// 人员等级：chief / advanced
    #[arg(long)]
    pub level: Option<String>,

    /// 溢价率（0-50，百分比整数）
    #[arg(long)]
    pub premium: Option<u32>,

    /// 内置报价样例：retrospective
    #[arg(long)]
    pub example: Option<String>,

    /// 报价项目名称（明细报价模式）
    #[arg(long)]
    pub project: Option<String>,

    /// 客户名称（明细报价模式）
    #[arg(long)]
    pub client: Option<String>,

    /// 报价明细，格式：名称|单价|数量|折扣，可重复；金额单位为万元
    #[arg(long = "item")]
    pub items: Vec<String>,

    /// 定价说明（明细报价模式）
    #[arg(long)]
    pub note: Option<String>,
}

fn level_from_str(s: &str) -> Option<PersonnelLevel> {
    match s {
        "chief" => Some(PersonnelLevel::Chief),
        "advanced" => Some(PersonnelLevel::Advanced),
        _ => None,
    }
}

fn level_label(level: PersonnelLevel) -> &'static str {
    match level {
        PersonnelLevel::Chief => "首席",
        PersonnelLevel::Advanced => "高级",
        _ => "未知",
    }
}

fn approval_label(t: ApprovalType) -> &'static str {
    match t {
        ApprovalType::Major => "重大报价（管理层审批）",
        ApprovalType::Discount => "让利报价（管理层审批）",
        ApprovalType::Standard => "标准报价（业务线负责人审批）",
    }
}

fn format_quotation(q: &Quotation) -> String {
    let s = q.summary();
    format!(
        r#"## 报价单

| 项目 | 值 |
|------|-----|
| 人员等级 | {level} |
| 服务时长 | {hours} 小时 |
| 单价 | {rate} 元/小时 |
| 基础总价 | {base} 元 |
| 溢价率 | {premium_rate}% |
| 溢价金额 | {premium_amt} 元 |
| 折扣率 | {discount_rate}% |
| 折后总价 | {total} 元 |
| 审批类型 | {approval} |
"#,
        level = level_label(
            q.items
                .first()
                .map(|i| i.level)
                .unwrap_or(PersonnelLevel::Advanced)
        ),
        hours = s.total_hours,
        rate = s.base_total / s.total_hours,
        base = s.base_total,
        premium_rate = (s.premium_rate * 100.0) as u32,
        premium_amt = s.premium_amount,
        discount_rate = (s.discount_rate * 100.0) as u32,
        total = s.total,
        approval = approval_label(s.approval_type),
    )
}

pub fn run(args: &QuoteArgs) -> Result<()> {
    if uses_product_quote_mode(args) {
        let q = build_product_quotation(args)?;
        print!("{}", format_product_quotation(&q)?);
        return Ok(());
    }

    let level_name = args.level.as_deref().unwrap_or("advanced");
    let level = match level_from_str(level_name) {
        Some(l) => l,
        None => {
            eprintln!(
                "错误: 不支持的人员等级 '{}'，支持 chief/advanced",
                level_name
            );
            return Ok(());
        }
    };

    let premium = args.premium.unwrap_or(0);
    if premium > 50 {
        eprintln!("错误: 溢价率不能超过 50%");
        return Ok(());
    }

    let hours = args.hours.unwrap_or(8.0);
    if !hours.is_finite() || hours <= 0.0 {
        eprintln!("错误: 服务时长必须是大于 0 的有限数字");
        return Ok(());
    }

    let q = Quotation {
        items: vec![ServiceItem {
            name: "服务",
            hours,
            level,
        }],
        premium_rate: premium as f64 / 100.0,
    };

    print!("{}", format_quotation(&q));
    Ok(())
}

fn uses_product_quote_mode(args: &QuoteArgs) -> bool {
    args.example.is_some()
        || !args.items.is_empty()
        || args.project.is_some()
        || args.client.is_some()
        || args.note.is_some()
}

fn build_product_quotation(args: &QuoteArgs) -> Result<ProductQuotation> {
    if args.hours.is_some() || args.level.is_some() || args.premium.is_some() {
        bail!("hourly quote options cannot be combined with product quote options");
    }

    if let Some(example) = args.example.as_deref() {
        if example != RETROSPECTIVE_EXAMPLE {
            bail!("unsupported quote example '{example}', supported: retrospective");
        }
        if !args.items.is_empty()
            || args.project.is_some()
            || args.client.is_some()
            || args.note.is_some()
        {
            bail!("--example cannot be combined with --item, --project, --client, or --note");
        }
        return Ok(retrospective_product_quotation());
    }

    let items = args
        .items
        .iter()
        .map(|raw| parse_product_quote_item(raw))
        .collect::<Result<Vec<_>>>()?;

    let q = ProductQuotation {
        project: args
            .project
            .as_deref()
            .map(|value| parse_required_text(value, "project"))
            .transpose()?
            .ok_or_else(|| anyhow!("--project is required when using --item"))?,
        client: args
            .client
            .as_deref()
            .map(|value| parse_required_text(value, "client"))
            .transpose()?
            .ok_or_else(|| anyhow!("--client is required when using --item"))?,
        items,
        note: args.note.clone(),
    };

    q.summary()?;
    Ok(q)
}

pub fn format_product_quotation(q: &ProductQuotation) -> Result<String> {
    let summary = q.summary()?;
    let mut out = String::new();

    out.push_str("## 报价单\n\n");
    out.push_str(&format!("项目：{}\n", q.project));
    out.push_str(&format!("客户：{}\n\n", q.client));
    out.push_str("| 明细 | 单价（万元） | 数量 | 折扣 | 小计（万元） |\n");
    out.push_str("|------|-------------|------|------|-------------|\n");

    for line in summary.lines {
        out.push_str(&format!(
            "| {} | {} | {} | {} | {} |\n",
            line.name,
            format_amount(line.unit_price),
            format_quantity(line.quantity),
            format_discount(line.discount),
            format_amount(line.subtotal)
        ));
    }

    out.push_str(&format!(
        "\n合计：{} 万元\n",
        format_amount(summary.total_amount)
    ));

    if let Some(note) = q.note.as_deref().map(str::trim).filter(|s| !s.is_empty()) {
        out.push_str(&format!("\n定价说明：{}\n", note));
    }

    Ok(out)
}

fn format_amount(value: f64) -> String {
    format!("{:.1}", (value * 10.0).round() / 10.0)
}

fn format_quantity(value: f64) -> String {
    if (value - value.trunc()).abs() < 0.000001 {
        format!("{value:.0}")
    } else {
        format!("{value:.2}")
    }
}

fn format_discount(value: f64) -> String {
    format!("{:.0}%", value * 100.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tutorial_case() {
        let q = Quotation {
            items: vec![
                ServiceItem {
                    name: "准备",
                    hours: 16.0,
                    level: PersonnelLevel::Chief,
                },
                ServiceItem {
                    name: "交付",
                    hours: 16.0,
                    level: PersonnelLevel::Chief,
                },
                ServiceItem {
                    name: "回访",
                    hours: 4.0,
                    level: PersonnelLevel::Chief,
                },
            ],
            premium_rate: 0.30,
        };
        let s = q.summary();
        assert_eq!(s.total_hours, 36.0);
        assert_eq!(s.base_total, 72000.0);
        assert_eq!(s.premium_amount, 21600.0);
        assert_eq!(s.discount_rate, 0.15);
        assert_eq!(s.total, 79560.0);
        assert_eq!(s.approval_type as i32, ApprovalType::Major as i32);
    }

    #[test]
    fn test_standard_quotation() {
        let q = Quotation {
            items: vec![ServiceItem {
                name: "咨询",
                hours: 8.0,
                level: PersonnelLevel::Advanced,
            }],
            premium_rate: 0.0,
        };
        let s = q.summary();
        assert_eq!(s.base_total, 8000.0);
        assert_eq!(s.discount_rate, 0.0);
        assert_eq!(s.total, 8000.0);
        assert_eq!(s.approval_type as i32, ApprovalType::Standard as i32);
    }

    #[test]
    fn test_discount_10h() {
        let q = Quotation {
            items: vec![ServiceItem {
                name: "咨询",
                hours: 10.0,
                level: PersonnelLevel::Advanced,
            }],
            premium_rate: 0.0,
        };
        let s = q.summary();
        assert_eq!(s.discount_rate, 0.10);
        assert_eq!(s.total, 9000.0);
    }

    #[test]
    fn test_discount_20h() {
        let q = Quotation {
            items: vec![ServiceItem {
                name: "咨询",
                hours: 20.0,
                level: PersonnelLevel::Advanced,
            }],
            premium_rate: 0.0,
        };
        let s = q.summary();
        assert_eq!(s.discount_rate, 0.15);
        assert_eq!(s.total, 17000.0);
    }

    #[test]
    fn test_mixed_levels() {
        let q = Quotation {
            items: vec![
                ServiceItem {
                    name: "设计",
                    hours: 4.0,
                    level: PersonnelLevel::Chief,
                },
                ServiceItem {
                    name: "执行",
                    hours: 16.0,
                    level: PersonnelLevel::Advanced,
                },
            ],
            premium_rate: 0.0,
        };
        let s = q.summary();
        assert_eq!(s.base_total, 24000.0);
        assert_eq!(s.discount_rate, 0.15);
    }

    #[test]
    fn test_format_standard() {
        let q = Quotation {
            items: vec![ServiceItem {
                name: "咨询",
                hours: 8.0,
                level: PersonnelLevel::Advanced,
            }],
            premium_rate: 0.0,
        };
        let out = format_quotation(&q);
        assert!(out.contains("8000 元"));
        assert!(out.contains("标准报价"));
    }

    #[test]
    fn test_format_with_premium() {
        let q = Quotation {
            items: vec![ServiceItem {
                name: "内训",
                hours: 36.0,
                level: PersonnelLevel::Chief,
            }],
            premium_rate: 0.30,
        };
        let out = format_quotation(&q);
        assert!(out.contains("72000 元"));
        assert!(out.contains("重大报价"));
    }

    #[test]
    fn test_format_with_discount() {
        let q = Quotation {
            items: vec![ServiceItem {
                name: "咨询",
                hours: 10.0,
                level: PersonnelLevel::Advanced,
            }],
            premium_rate: 0.0,
        };
        let out = format_quotation(&q);
        assert!(out.contains("9000 元"));
        assert!(out.contains("| 折扣率 | 10% |"));
    }

    fn assert_close(actual: f64, expected: f64) {
        assert!(
            (actual - expected).abs() < 0.000001,
            "expected {expected}, got {actual}"
        );
    }

    #[test]
    fn test_product_quote_retrospective_example() {
        let q = retrospective_product_quotation();
        let s = q.summary().expect("product quote should calculate");

        assert_eq!(q.project, "议事决议数据需求点");
        assert_eq!(s.line_count, 3);
        assert_close(s.total_amount, 0.8);
    }

    #[test]
    fn test_product_quote_item_subtotal_with_discount() {
        let item = ProductQuoteItem {
            name: "质量基线报告".into(),
            unit_price: 1.5,
            quantity: 2.0,
            discount: 0.9,
        };

        assert_close(item.subtotal(), 2.7);
    }

    #[test]
    fn test_parse_product_quote_item() {
        let item = parse_product_quote_item("治理视图|0.2|1|0.85").expect("item should parse");

        assert_eq!(item.name, "治理视图");
        assert_close(item.unit_price, 0.2);
        assert_close(item.quantity, 1.0);
        assert_close(item.discount, 0.85);
        assert_close(item.subtotal(), 0.17);
    }

    #[test]
    fn test_parse_product_quote_item_rejects_invalid_discount() {
        let err = parse_product_quote_item("治理视图|0.2|1|1.2").expect_err("discount should fail");

        assert!(err.to_string().contains("discount"));
    }

    #[test]
    fn test_parse_product_quote_item_rejects_non_finite_numbers() {
        let nan_err = parse_product_quote_item("治理视图|NaN|1|1").expect_err("NaN should fail");
        let infinity_err =
            parse_product_quote_item("治理视图|inf|1|1").expect_err("infinity should fail");

        assert!(nan_err.to_string().contains("finite"));
        assert!(infinity_err.to_string().contains("finite"));
    }

    #[test]
    fn test_product_quote_rejects_hourly_options() {
        let args = QuoteArgs {
            hours: Some(100.0),
            level: None,
            premium: None,
            example: None,
            project: Some("测试项目".into()),
            client: Some("测试客户".into()),
            items: vec!["A|0.2|1|1".into()],
            note: None,
        };

        let err = build_product_quotation(&args).expect_err("mixed quote modes should fail");

        assert!(err.to_string().contains("cannot be combined"));
    }

    #[test]
    fn test_product_quote_requires_project_and_client() {
        let missing_project = QuoteArgs {
            hours: None,
            level: None,
            premium: None,
            example: None,
            project: None,
            client: Some("测试客户".into()),
            items: vec!["A|0.2|1|1".into()],
            note: None,
        };
        let missing_client = QuoteArgs {
            hours: None,
            level: None,
            premium: None,
            example: None,
            project: Some("测试项目".into()),
            client: None,
            items: vec!["A|0.2|1|1".into()],
            note: None,
        };

        let project_err =
            build_product_quotation(&missing_project).expect_err("project should be required");
        let client_err =
            build_product_quotation(&missing_client).expect_err("client should be required");

        assert!(project_err.to_string().contains("--project"));
        assert!(client_err.to_string().contains("--client"));
    }

    #[test]
    fn test_example_rejects_overrides() {
        let args = QuoteArgs {
            hours: None,
            level: None,
            premium: None,
            example: Some("retrospective".into()),
            project: Some("自定义项目".into()),
            client: None,
            items: vec![],
            note: None,
        };

        let err = build_product_quotation(&args).expect_err("example overrides should fail");

        assert!(err.to_string().contains("--example"));
    }

    #[test]
    fn test_product_quote_rejects_empty_items() {
        let q = ProductQuotation {
            project: "空报价".into(),
            client: "测试客户".into(),
            items: vec![],
            note: None,
        };

        let err = q.summary().expect_err("empty product quote should fail");

        assert!(err.to_string().contains("at least one item"));
    }

    #[test]
    fn test_format_product_quote_contains_retrospective_details() {
        let q = retrospective_product_quotation();
        let out = format_product_quotation(&q).expect("product quote should format");

        assert!(out.contains("## 报价单"));
        assert!(out.contains("议事决议数据需求点"));
        assert!(out.contains("量潮科技（内部项目）"));
        assert!(out.contains("议事决议数据-决议档案"));
        assert!(out.contains("合计：0.8 万元"));
        assert!(out.contains("成本法约0.5万元"));
    }
}
