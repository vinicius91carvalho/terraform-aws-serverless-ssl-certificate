/*
  Módulo criado para criação de um certificado SSL para o domínio e para os subdomínios
  É necessário comprar um domínio e após, criar uma zona no Route53
  Observação importante:
    - Checar se os servidores DNS na lista NS da zona criada são os mesmos dos registrados no domínio.
*/

provider "aws" {
  region = var.region
}

/*
  Obtém a zona da AWS
*/
data "aws_route53_zone" "zone" {
  name         = "${var.domain}."
  private_zone = false
}

/*
  Registra o certificado para o domínio e subdomínios
  Exemplo:
    - domain
    - *.domain
*/
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

/*
  Inseri o CNAME gerado pelo ACM no Route53
*/
resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.zone.id
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

/*
  Aguarda a validação do certificado pelo ACM
*/
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
