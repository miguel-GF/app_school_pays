class Student {
  const Student({
    required this.id,
    required this.matricula,
    required this.name,
    required this.program,
    required this.semester,
    required this.email,
    required this.campus,
  });

  final String id;
  final String matricula;
  final String name;
  final String program;
  final int semester;
  final String email;
  final String campus;

  String get firstName => name.split(' ').first;
}

/// Un adeudo: colegiatura, inscripción, etc.
class Charge {
  Charge({
    required this.id,
    required this.concept,
    required this.period,
    required this.amount,
    required this.dueDate,
    this.paid = false,
  });

  final String id;
  final String concept;
  final String period;
  final double amount;
  final DateTime dueDate;
  bool paid;

  bool isOverdue(DateTime now) => !paid && dueDate.isBefore(now);
}

/// Un pago ya realizado.
class Payment {
  const Payment({
    required this.id,
    required this.chargeId,
    required this.concept,
    required this.amount,
    required this.date,
    required this.method,
    required this.folio,
  });

  final String id;
  final String chargeId;
  final String concept;
  final double amount;
  final DateTime date;

  /// Texto para mostrar: "Visa •••• 4242", "Transferencia SPEI".
  final String method;
  final String folio;
}

/// Tarjeta guardada. Nunca contiene el número completo ni el CVV:
/// solo lo necesario para mostrarla y el token que entrega la pasarela.
class SavedCard {
  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.holder,
    required this.token,
  });

  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final String holder;
  final String token;

  String get label => '$brand •••• $last4';

  String get expiry =>
      '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';
}

class Grade {
  const Grade({
    required this.subject,
    required this.credits,
    required this.score,
  });

  final String subject;
  final int credits;
  final double score;
}

/// Datos que ve el alumno para pagar por transferencia.
class TransferInstructions {
  const TransferInstructions({
    required this.beneficiary,
    required this.bank,
    required this.clabe,
    required this.reference,
    required this.concept,
    required this.amount,
  });

  final String beneficiary;
  final String bank;
  final String clabe;
  final String reference;
  final String concept;
  final double amount;
}
