locals {
  name = "${var.project}-${var.environment}"
  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

data "aws_availability_zones" "this" {
  state = "available"
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.tags, { Name = "${local.name}-vpc" })
}

# IGW for public subnets
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}

# Create public & private subnets across AZs (2 by default)
# We split the /16 into /20s (adjust as you like)
locals {
  azs           = slice(data.aws_availability_zones.this.names, 0, var.az_count)
  public_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]                # /20s
  private_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]            # offset
}

resource "aws_subnet" "public" {
  for_each                = { for idx, az in local.azs : az => {
    cidr = local.public_cidrs[idx]
  }}
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  tags = merge(local.tags, { Name = "${local.name}-public-${each.key}", Tier = "public" })
}

resource "aws_subnet" "private" {
  for_each          = { for idx, az in local.azs : az => {
    cidr = local.private_cidrs[idx]
  }}
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value.cidr
  tags = merge(local.tags, { Name = "${local.name}-private-${each.key}", Tier = "private" })
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT (optional, single NAT in first public subnet to save cost)
resource "aws_eip" "nat" {
  count = var.enable_nat ? 1 : 0
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${local.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = merge(local.tags, { Name = "${local.name}-nat" })
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count = var.enable_nat ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-private-rt" })
}

resource "aws_route" "private_internet_via_nat" {
  count                    = var.enable_nat ? 1 : 0
  route_table_id           = aws_route_table.private[0].id
  destination_cidr_block   = "0.0.0.0/0"
  nat_gateway_id           = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = var.enable_nat ? aws_subnet.private : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[0].id
}
