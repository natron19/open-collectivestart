class FoundingStarterPackParser
  Result = Struct.new(:conversation_summary, :business_model_canvas,
                      :legal_form_comparison, :open_questions, keyword_init: true)

  ANCHORS = {
    artifact1:      /===\s*ARTIFACT\s+1[^=]*===/i,
    artifact2:      /===\s*ARTIFACT\s+2[^=]*===/i,
    artifact3:      /===\s*ARTIFACT\s+3[^=]*===/i,
    open_questions: /===\s*OPEN\s+QUESTIONS[^=]*===/i
  }.freeze

  ORDERED_KEYS = %i[artifact1 artifact2 artifact3 open_questions].freeze

  def self.parse(raw_text)
    new(raw_text).parse
  end

  def initialize(raw_text)
    @raw = raw_text.to_s
  end

  def parse
    sections = extract_sections
    Result.new(
      conversation_summary:  sections[:artifact1],
      business_model_canvas: sections[:artifact2],
      legal_form_comparison: sections[:artifact3],
      open_questions:        sections[:open_questions]
    )
  end

  private

  def extract_sections
    positions = ANCHORS.transform_values do |pattern|
      match = @raw.match(pattern)
      match ? match.end(0) : nil
    end

    sections = {}
    ORDERED_KEYS.each_with_index do |key, idx|
      start_pos = positions[key]
      next unless start_pos

      next_key  = ORDERED_KEYS[(idx + 1)..].find { |k| positions[k] }
      end_pos   = next_key ? @raw.index(ANCHORS[next_key]) : @raw.length

      sections[key] = @raw[start_pos...end_pos].strip
    end

    sections
  end
end
