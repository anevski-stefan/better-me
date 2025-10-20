import 'dart:math';

class MotivationalQuote {
  final String text;
  final String author;
  final String category;

  const MotivationalQuote({
    required this.text,
    required this.author,
    required this.category,
  });
}

class QuotesService {
  static const List<MotivationalQuote> _quotes = [
    MotivationalQuote(
      text: "The only way to do great work is to love what you do.",
      author: "Steve Jobs",
      category: "work",
    ),
    MotivationalQuote(
      text: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
      author: "Winston Churchill",
      category: "perseverance",
    ),
    MotivationalQuote(
      text: "The future belongs to those who believe in the beauty of their dreams.",
      author: "Eleanor Roosevelt",
      category: "dreams",
    ),
    MotivationalQuote(
      text: "It is during our darkest moments that we must focus to see the light.",
      author: "Aristotle",
      category: "resilience",
    ),
    MotivationalQuote(
      text: "The way to get started is to quit talking and begin doing.",
      author: "Walt Disney",
      category: "action",
    ),
    MotivationalQuote(
      text: "Don't be pushed around by the fears in your mind. Be led by the dreams in your heart.",
      author: "Roy T. Bennett",
      category: "courage",
    ),
    MotivationalQuote(
      text: "The only impossible journey is the one you never begin.",
      author: "Tony Robbins",
      category: "beginning",
    ),
    MotivationalQuote(
      text: "In the middle of difficulty lies opportunity.",
      author: "Albert Einstein",
      category: "opportunity",
    ),
    MotivationalQuote(
      text: "Believe you can and you're halfway there.",
      author: "Theodore Roosevelt",
      category: "belief",
    ),
    MotivationalQuote(
      text: "The only person you are destined to become is the person you decide to be.",
      author: "Ralph Waldo Emerson",
      category: "self-improvement",
    ),
    MotivationalQuote(
      text: "Go confidently in the direction of your dreams. Live the life you have imagined.",
      author: "Henry David Thoreau",
      category: "dreams",
    ),
    MotivationalQuote(
      text: "When you have a dream, you've got to grab it and never let go.",
      author: "Carol Burnett",
      category: "dreams",
    ),
    MotivationalQuote(
      text: "Nothing is impossible, the word itself says 'I'm possible'!",
      author: "Audrey Hepburn",
      category: "possibility",
    ),
    MotivationalQuote(
      text: "There is nothing impossible to they who will try.",
      author: "Alexander the Great",
      category: "perseverance",
    ),
    MotivationalQuote(
      text: "The bad news is time flies. The good news is you're the pilot.",
      author: "Michael Altshuler",
      category: "time",
    ),
    MotivationalQuote(
      text: "Life has got all those twists and turns. You've got to hold on tight and off you go.",
      author: "Nicole Kidman",
      category: "life",
    ),
    MotivationalQuote(
      text: "Keep your face always toward the sunshine—and shadows will fall behind you.",
      author: "Walt Whitman",
      category: "positivity",
    ),
    MotivationalQuote(
      text: "Be courageous. Challenge orthodoxy. Stand up for what you believe in.",
      author: "Tim Cook",
      category: "courage",
    ),
    MotivationalQuote(
      text: "When you give joy to other people, you get more joy in return. You should give a good thought to happiness that you can give out.",
      author: "Eleanor Roosevelt",
      category: "happiness",
    ),
    MotivationalQuote(
      text: "When you change your thoughts, remember to also change your world.",
      author: "Norman Vincent Peale",
      category: "mindset",
    ),
    MotivationalQuote(
      text: "It is only when we take chances, when our lives improve. The initial and the most difficult risk that we need to take is to become honest.",
      author: "Walter Anderson",
      category: "honesty",
    ),
    MotivationalQuote(
      text: "Nature has given us all the pieces required to achieve exceptional wellness and health, but has left it to us to put these pieces together.",
      author: "Diane McLaren",
      category: "health",
    ),
    MotivationalQuote(
      text: "Success is not how high you have climbed, but how you make a positive difference to the world.",
      author: "Roy T. Bennett",
      category: "success",
    ),
    MotivationalQuote(
      text: "For every reason it's not possible, there are hundreds of people who have faced the same circumstances and succeeded.",
      author: "Jack Canfield",
      category: "success",
    ),
    MotivationalQuote(
      text: "Think big thoughts but relish small pleasures.",
      author: "H. Jackson Brown Jr.",
      category: "mindfulness",
    ),
    MotivationalQuote(
      text: "You are never too old to set another goal or to dream a new dream.",
      author: "C.S. Lewis",
      category: "dreams",
    ),
    MotivationalQuote(
      text: "At the end of the day, whether or not those people are comfortable with how you're living your life doesn't matter. What matters is whether you're comfortable with it.",
      author: "Dr. Phil",
      category: "self-acceptance",
    ),
    MotivationalQuote(
      text: "People who are crazy enough to think they can change the world, are the ones who do.",
      author: "Rob Siltanen",
      category: "change",
    ),
    MotivationalQuote(
      text: "Failure will never overtake me if my determination to succeed is strong enough.",
      author: "Og Mandino",
      category: "determination",
    ),
    MotivationalQuote(
      text: "Entrepreneurs are great at dealing with uncertainty and also very good at minimizing risk. That's the classic entrepreneur.",
      author: "Mohnish Pabrai",
      category: "entrepreneurship",
    ),
    MotivationalQuote(
      text: "We may encounter many defeats but we must not be defeated.",
      author: "Maya Angelou",
      category: "resilience",
    ),
  ];

  /// Get a random motivational quote
  static MotivationalQuote getRandomQuote() {
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    return _quotes[random.nextInt(_quotes.length)];
  }

  /// Get a quote by category
  static MotivationalQuote? getQuoteByCategory(String category) {
    final categoryQuotes = _quotes.where((quote) => quote.category == category).toList();
    if (categoryQuotes.isEmpty) return null;
    
    final random = Random();
    return categoryQuotes[random.nextInt(categoryQuotes.length)];
  }

  /// Get today's quote (deterministic based on date)
  static MotivationalQuote getTodaysQuote() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _quotes.length;
    return _quotes[index];
  }

  /// Get all available categories
  static List<String> getAllCategories() {
    return _quotes.map((quote) => quote.category).toSet().toList()..sort();
  }

  /// Get all quotes
  static List<MotivationalQuote> getAllQuotes() {
    return List.unmodifiable(_quotes);
  }
}
