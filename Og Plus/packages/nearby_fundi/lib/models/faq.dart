class Faq {
  final int id;
  final String question;
  final String answer;
  final int order;

  Faq({required this.id, required this.question, required this.answer, required this.order});

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
    id: json['id'] ?? 0,
    question: json['question'] ?? '',
    answer: json['answer'] ?? '',
    order: json['order'] ?? 0,
  );
}