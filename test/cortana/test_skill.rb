# frozen_string_literal: true

require "test_helper"

class TestSkill < Minitest::Test
  def setup
    @skill = Cortana::Skill.new
  end

  def test_name_raises_not_implemented
    assert_raises(Cortana::SkillNotImplementedError) { @skill.name }
  end

  def test_description_raises_not_implemented
    assert_raises(Cortana::SkillNotImplementedError) { @skill.description }
  end

  def test_execute_raises_not_implemented
    assert_raises(Cortana::SkillNotImplementedError) { @skill.execute(nil) }
  end
end
