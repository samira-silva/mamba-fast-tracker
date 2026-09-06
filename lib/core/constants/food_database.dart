/// Base local de alimentos comuns (calorias por 100g), usada só pra
/// SUGERIR um valor de calorias quando o usuário digita o nome de uma
/// refeição — a pessoa sempre pode ignorar/editar o valor sugerido. Fica
/// embutida no app (sem API externa) pra não depender de rede e não virar
/// mais um ponto de falha.
///
/// Valores aproximados, baseados em tabelas nutricionais públicas
/// (TACO/USDA), só como referência — não é orientação nutricional.
const Map<String, int> kFoodCaloriesPer100g = {
  'Arroz branco cozido': 128,
  'Arroz integral cozido': 123,
  'Feijão carioca cozido': 76,
  'Feijão preto cozido': 77,
  'Frango grelhado (peito)': 165,
  'Frango assado (coxa)': 209,
  'Carne bovina grelhada': 250,
  'Carne moída refogada': 212,
  'Ovo cozido': 155,
  'Ovo frito': 196,
  'Pão francês': 300,
  'Pão de forma integral': 247,
  'Batata cozida': 87,
  'Batata frita': 312,
  'Batata doce cozida': 86,
  'Macarrão cozido': 158,
  'Queijo mussarela': 280,
  'Queijo minas': 264,
  'Iogurte natural': 61,
  'Leite integral': 61,
  'Banana': 89,
  'Maçã': 52,
  'Laranja': 47,
  'Mamão': 43,
  'Abacate': 160,
  'Salada verde (folhas)': 15,
  'Tomate': 18,
  'Cenoura crua': 41,
  'Brócolis cozido': 35,
  'Aveia em flocos': 389,
  'Granola': 471,
  'Pão de queijo': 350,
  'Tapioca': 240,
  'Feijoada': 180,
  'Pizza (fatia média)': 266,
  'Hambúrguer': 295,
  'Sanduíche natural': 210,
  'Chocolate ao leite': 535,
  'Amendoim': 567,
  'Castanha do Pará': 656,
  'Azeite de oliva': 884,
  'Manteiga': 717,
  'Whey protein (scoop)': 400,
  'Suco de laranja natural': 45,
  'Refrigerante': 42,
  'Água de coco': 19,
};

/// Peso médio (em gramas) de UMA unidade típica, só pra alimentos que
/// fazem sentido serem contados por unidade (ex: 1 banana, 1 ovo, 1 fatia
/// de pão) em vez de pesados. Alimentos que não aparecem aqui (arroz,
/// feijão, etc.) só aceitam quantidade em gramas — não faz sentido contar
/// "1 unidade de arroz". Valores aproximados de referência.
const Map<String, int> kFoodUnitWeightGrams = {
  'Banana': 118,
  'Maçã': 130,
  'Laranja': 150,
  'Mamão': 400,
  'Abacate': 200,
  'Ovo cozido': 50,
  'Ovo frito': 50,
  'Pão francês': 50,
  'Pão de forma integral': 25,
  'Pão de queijo': 30,
  'Batata cozida': 150,
  'Batata doce cozida': 130,
  'Hambúrguer': 150,
  'Sanduíche natural': 120,
  'Tapioca': 100,
};

/// Retorna sugestões de nomes de alimentos que contêm [query] (case
/// insensitive), limitado a [limit] resultados. Usado pelo Autocomplete no
/// formulário de refeição.
List<String> searchFoods(String query, {int limit = 6}) {
  if (query.trim().isEmpty) return const [];
  final q = query.toLowerCase();
  return kFoodCaloriesPer100g.keys
      .where((name) => name.toLowerCase().contains(q))
      .take(limit)
      .toList();
}

/// Calorias sugeridas pra uma quantidade em gramas de um alimento
/// conhecido. Retorna null se o alimento não estiver na base.
int? suggestedCalories(String foodName, double grams) {
  final per100g = kFoodCaloriesPer100g[foodName];
  if (per100g == null) return null;
  return ((per100g * grams) / 100).round();
}
