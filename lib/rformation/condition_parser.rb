module RFormation::Condition
  include Treetop::Runtime

  def root
    @root || :root
  end

  module Root0
    def ospace
      elements[0]
    end

    def condition
      elements[1]
    end

    def ospace
      elements[2]
    end
  end

  def _nt_root
    start_index = index
    if node_cache[:root].has_key?(index)
      cached = node_cache[:root][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_ospace
    s0 << r1
    if r1
      r2 = _nt_condition
      s0 << r2
      if r2
        r3 = _nt_ospace
        s0 << r3
      end
    end
    if s0.last
      r0 = (RFormation::ConditionAST::Root).new(input, i0...index, s0)
      r0.extend(Root0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:root][start_index] = r0

    return r0
  end

  def _nt_condition
    start_index = index
    if node_cache[:condition].has_key?(index)
      cached = node_cache[:condition][index]
      @index = cached.interval.end if cached
      return cached
    end

    r0 = _nt_or_condition

    node_cache[:condition][start_index] = r0

    return r0
  end

  module OrCondition0
    def exp1
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

    def exp2
      elements[4]
    end
  end

  def _nt_or_condition
    start_index = index
    if node_cache[:or_condition].has_key?(index)
      cached = node_cache[:or_condition][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    i1, s1 = index, []
    r2 = _nt_and_condition
    s1 << r2
    if r2
      r3 = _nt_space
      s1 << r3
      if r3
        if input.index("or", index) == index
          r4 = (SyntaxNode).new(input, index...(index + 2))
          @index += 2
        else
          terminal_parse_failure("or")
          r4 = nil
        end
        s1 << r4
        if r4
          r5 = _nt_space
          s1 << r5
          if r5
            r6 = _nt_or_condition
            s1 << r6
          end
        end
      end
    end
    if s1.last
      r1 = (RFormation::ConditionAST::Or).new(input, i1...index, s1)
      r1.extend(OrCondition0)
    else
      self.index = i1
      r1 = nil
    end
    if r1
      r0 = r1
    else
      r7 = _nt_and_condition
      if r7
        r0 = r7
      else
        self.index = i0
        r0 = nil
      end
    end

    node_cache[:or_condition][start_index] = r0

    return r0
  end

  module AndCondition0
    def exp1
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

    def exp2
      elements[4]
    end
  end

  def _nt_and_condition
    start_index = index
    if node_cache[:and_condition].has_key?(index)
      cached = node_cache[:and_condition][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    i1, s1 = index, []
    r2 = _nt_atomic_condition
    s1 << r2
    if r2
      r3 = _nt_space
      s1 << r3
      if r3
        if input.index("and", index) == index
          r4 = (SyntaxNode).new(input, index...(index + 3))
          @index += 3
        else
          terminal_parse_failure("and")
          r4 = nil
        end
        s1 << r4
        if r4
          r5 = _nt_space
          s1 << r5
          if r5
            r6 = _nt_and_condition
            s1 << r6
          end
        end
      end
    end
    if s1.last
      r1 = (RFormation::ConditionAST::And).new(input, i1...index, s1)
      r1.extend(AndCondition0)
    else
      self.index = i1
      r1 = nil
    end
    if r1
      r0 = r1
    else
      r7 = _nt_atomic_condition
      if r7
        r0 = r7
      else
        self.index = i0
        r0 = nil
      end
    end

    node_cache[:and_condition][start_index] = r0

    return r0
  end

  module AtomicCondition0
    def ospace
      elements[1]
    end

    def condition
      elements[2]
    end

    def ospace
      elements[3]
    end

  end

  module AtomicCondition1
    def ospace
      elements[1]
    end

    def ospace
      elements[3]
    end

    def exp
      elements[4]
    end

    def ospace
      elements[5]
    end

  end

  module AtomicCondition2
    def f
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

    def v
      elements[4]
    end
  end

  module AtomicCondition3
    def f
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

    def space
      elements[5]
    end

    def v
      elements[6]
    end
  end

  module AtomicCondition4
    def f
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

  end

  module AtomicCondition5
    def f
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

  end

  module AtomicCondition6
    def f
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

  end

  module AtomicCondition7
    def f
      elements[0]
    end

    def space
      elements[1]
    end

    def space
      elements[3]
    end

    def space
      elements[5]
    end

  end

  def _nt_atomic_condition
    start_index = index
    if node_cache[:atomic_condition].has_key?(index)
      cached = node_cache[:atomic_condition][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    i1, s1 = index, []
    if input.index("(", index) == index
      r2 = (SyntaxNode).new(input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure("(")
      r2 = nil
    end
    s1 << r2
    if r2
      r3 = _nt_ospace
      s1 << r3
      if r3
        r4 = _nt_condition
        s1 << r4
        if r4
          r5 = _nt_ospace
          s1 << r5
          if r5
            if input.index(")", index) == index
              r6 = (SyntaxNode).new(input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure(")")
              r6 = nil
            end
            s1 << r6
          end
        end
      end
    end
    if s1.last
      r1 = (RFormation::ConditionAST::Parentheses).new(input, i1...index, s1)
      r1.extend(AtomicCondition0)
    else
      self.index = i1
      r1 = nil
    end
    if r1
      r0 = r1
    else
      i7, s7 = index, []
      if input.index("not", index) == index
        r8 = (SyntaxNode).new(input, index...(index + 3))
        @index += 3
      else
        terminal_parse_failure("not")
        r8 = nil
      end
      s7 << r8
      if r8
        r9 = _nt_ospace
        s7 << r9
        if r9
          if input.index("(", index) == index
            r10 = (SyntaxNode).new(input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("(")
            r10 = nil
          end
          s7 << r10
          if r10
            r11 = _nt_ospace
            s7 << r11
            if r11
              r12 = _nt_condition
              s7 << r12
              if r12
                r13 = _nt_ospace
                s7 << r13
                if r13
                  if input.index(")", index) == index
                    r14 = (SyntaxNode).new(input, index...(index + 1))
                    @index += 1
                  else
                    terminal_parse_failure(")")
                    r14 = nil
                  end
                  s7 << r14
                end
              end
            end
          end
        end
      end
      if s7.last
        r7 = (RFormation::ConditionAST::Not).new(input, i7...index, s7)
        r7.extend(AtomicCondition1)
      else
        self.index = i7
        r7 = nil
      end
      if r7
        r0 = r7
      else
        i15, s15 = index, []
        r16 = _nt_any_value
        s15 << r16
        if r16
          r17 = _nt_space
          s15 << r17
          if r17
            if input.index("equals", index) == index
              r18 = (SyntaxNode).new(input, index...(index + 6))
              @index += 6
            else
              terminal_parse_failure("equals")
              r18 = nil
            end
            s15 << r18
            if r18
              r19 = _nt_space
              s15 << r19
              if r19
                r20 = _nt_any_value
                s15 << r20
              end
            end
          end
        end
        if s15.last
          r15 = (RFormation::ConditionAST::Equals).new(input, i15...index, s15)
          r15.extend(AtomicCondition2)
        else
          self.index = i15
          r15 = nil
        end
        if r15
          r0 = r15
        else
          i21, s21 = index, []
          r22 = _nt_any_value
          s21 << r22
          if r22
            r23 = _nt_space
            s21 << r23
            if r23
              if input.index("not", index) == index
                r24 = (SyntaxNode).new(input, index...(index + 3))
                @index += 3
              else
                terminal_parse_failure("not")
                r24 = nil
              end
              s21 << r24
              if r24
                r25 = _nt_space
                s21 << r25
                if r25
                  if input.index("equals", index) == index
                    r26 = (SyntaxNode).new(input, index...(index + 6))
                    @index += 6
                  else
                    terminal_parse_failure("equals")
                    r26 = nil
                  end
                  s21 << r26
                  if r26
                    r27 = _nt_space
                    s21 << r27
                    if r27
                      r28 = _nt_any_value
                      s21 << r28
                    end
                  end
                end
              end
            end
          end
          if s21.last
            r21 = (RFormation::ConditionAST::NotEquals).new(input, i21...index, s21)
            r21.extend(AtomicCondition3)
          else
            self.index = i21
            r21 = nil
          end
          if r21
            r0 = r21
          else
            i29, s29 = index, []
            r30 = _nt_any_value
            s29 << r30
            if r30
              r31 = _nt_space
              s29 << r31
              if r31
                if input.index("is", index) == index
                  r32 = (SyntaxNode).new(input, index...(index + 2))
                  @index += 2
                else
                  terminal_parse_failure("is")
                  r32 = nil
                end
                s29 << r32
                if r32
                  r33 = _nt_space
                  s29 << r33
                  if r33
                    if input.index("on", index) == index
                      r34 = (SyntaxNode).new(input, index...(index + 2))
                      @index += 2
                    else
                      terminal_parse_failure("on")
                      r34 = nil
                    end
                    s29 << r34
                  end
                end
              end
            end
            if s29.last
              r29 = (RFormation::ConditionAST::IsOn).new(input, i29...index, s29)
              r29.extend(AtomicCondition4)
            else
              self.index = i29
              r29 = nil
            end
            if r29
              r0 = r29
            else
              i35, s35 = index, []
              r36 = _nt_any_value
              s35 << r36
              if r36
                r37 = _nt_space
                s35 << r37
                if r37
                  if input.index("is", index) == index
                    r38 = (SyntaxNode).new(input, index...(index + 2))
                    @index += 2
                  else
                    terminal_parse_failure("is")
                    r38 = nil
                  end
                  s35 << r38
                  if r38
                    r39 = _nt_space
                    s35 << r39
                    if r39
                      if input.index("off", index) == index
                        r40 = (SyntaxNode).new(input, index...(index + 3))
                        @index += 3
                      else
                        terminal_parse_failure("off")
                        r40 = nil
                      end
                      s35 << r40
                    end
                  end
                end
              end
              if s35.last
                r35 = (RFormation::ConditionAST::IsOff).new(input, i35...index, s35)
                r35.extend(AtomicCondition5)
              else
                self.index = i35
                r35 = nil
              end
              if r35
                r0 = r35
              else
                i41, s41 = index, []
                r42 = _nt_any_value
                s41 << r42
                if r42
                  r43 = _nt_space
                  s41 << r43
                  if r43
                    if input.index("is", index) == index
                      r44 = (SyntaxNode).new(input, index...(index + 2))
                      @index += 2
                    else
                      terminal_parse_failure("is")
                      r44 = nil
                    end
                    s41 << r44
                    if r44
                      r45 = _nt_space
                      s41 << r45
                      if r45
                        if input.index("empty", index) == index
                          r46 = (SyntaxNode).new(input, index...(index + 5))
                          @index += 5
                        else
                          terminal_parse_failure("empty")
                          r46 = nil
                        end
                        s41 << r46
                      end
                    end
                  end
                end
                if s41.last
                  r41 = (RFormation::ConditionAST::IsEmpty).new(input, i41...index, s41)
                  r41.extend(AtomicCondition6)
                else
                  self.index = i41
                  r41 = nil
                end
                if r41
                  r0 = r41
                else
                  i47, s47 = index, []
                  r48 = _nt_any_value
                  s47 << r48
                  if r48
                    r49 = _nt_space
                    s47 << r49
                    if r49
                      if input.index("is", index) == index
                        r50 = (SyntaxNode).new(input, index...(index + 2))
                        @index += 2
                      else
                        terminal_parse_failure("is")
                        r50 = nil
                      end
                      s47 << r50
                      if r50
                        r51 = _nt_space
                        s47 << r51
                        if r51
                          if input.index("not", index) == index
                            r52 = (SyntaxNode).new(input, index...(index + 3))
                            @index += 3
                          else
                            terminal_parse_failure("not")
                            r52 = nil
                          end
                          s47 << r52
                          if r52
                            r53 = _nt_space
                            s47 << r53
                            if r53
                              if input.index("empty", index) == index
                                r54 = (SyntaxNode).new(input, index...(index + 5))
                                @index += 5
                              else
                                terminal_parse_failure("empty")
                                r54 = nil
                              end
                              s47 << r54
                            end
                          end
                        end
                      end
                    end
                  end
                  if s47.last
                    r47 = (RFormation::ConditionAST::IsNotEmpty).new(input, i47...index, s47)
                    r47.extend(AtomicCondition7)
                  else
                    self.index = i47
                    r47 = nil
                  end
                  if r47
                    r0 = r47
                  else
                    self.index = i0
                    r0 = nil
                  end
                end
              end
            end
          end
        end
      end
    end

    node_cache[:atomic_condition][start_index] = r0

    return r0
  end

  module AnyValue0
  end

  module AnyValue1
  end

  module AnyValue2
  end

  module AnyValue3
  end

  module AnyValue4
  end

  module AnyValue5
  end

  def _nt_any_value
    start_index = index
    if node_cache[:any_value].has_key?(index)
      cached = node_cache[:any_value][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    s1, i1 = [], index
    loop do
      if input.index(Regexp.new('[^ \\t\\n\\r\\f()\'"`#]'), index) == index
        r2 = (SyntaxNode).new(input, index...(index + 1))
        @index += 1
      else
        r2 = nil
      end
      if r2
        s1 << r2
      else
        break
      end
    end
    if s1.empty?
      self.index = i1
      r1 = nil
    else
      r1 = RFormation::ConditionAST::Identifier.new(input, i1...index, s1)
    end
    if r1
      r0 = r1
    else
      i3, s3 = index, []
      if input.index('"', index) == index
        r4 = (SyntaxNode).new(input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('"')
        r4 = nil
      end
      s3 << r4
      if r4
        s5, i5 = [], index
        loop do
          i6 = index
          if input.index(Regexp.new('[^\\\\"]'), index) == index
            r7 = (SyntaxNode).new(input, index...(index + 1))
            @index += 1
          else
            r7 = nil
          end
          if r7
            r6 = r7
          else
            i8, s8 = index, []
            if input.index("\\", index) == index
              r9 = (SyntaxNode).new(input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure("\\")
              r9 = nil
            end
            s8 << r9
            if r9
              if index < input_length
                r10 = (SyntaxNode).new(input, index...(index + 1))
                @index += 1
              else
                terminal_parse_failure("any character")
                r10 = nil
              end
              s8 << r10
            end
            if s8.last
              r8 = (SyntaxNode).new(input, i8...index, s8)
              r8.extend(AnyValue0)
            else
              self.index = i8
              r8 = nil
            end
            if r8
              r6 = r8
            else
              self.index = i6
              r6 = nil
            end
          end
          if r6
            s5 << r6
          else
            break
          end
        end
        r5 = SyntaxNode.new(input, i5...index, s5)
        s3 << r5
        if r5
          if input.index('"', index) == index
            r11 = (SyntaxNode).new(input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure('"')
            r11 = nil
          end
          s3 << r11
        end
      end
      if s3.last
        r3 = (RFormation::ConditionAST::String).new(input, i3...index, s3)
        r3.extend(AnyValue1)
      else
        self.index = i3
        r3 = nil
      end
      if r3
        r0 = r3
      else
        i12, s12 = index, []
        if input.index("'", index) == index
          r13 = (SyntaxNode).new(input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("'")
          r13 = nil
        end
        s12 << r13
        if r13
          s14, i14 = [], index
          loop do
            i15 = index
            if input.index(Regexp.new('[^\\\\\']'), index) == index
              r16 = (SyntaxNode).new(input, index...(index + 1))
              @index += 1
            else
              r16 = nil
            end
            if r16
              r15 = r16
            else
              i17, s17 = index, []
              if input.index("\\", index) == index
                r18 = (SyntaxNode).new(input, index...(index + 1))
                @index += 1
              else
                terminal_parse_failure("\\")
                r18 = nil
              end
              s17 << r18
              if r18
                if index < input_length
                  r19 = (SyntaxNode).new(input, index...(index + 1))
                  @index += 1
                else
                  terminal_parse_failure("any character")
                  r19 = nil
                end
                s17 << r19
              end
              if s17.last
                r17 = (SyntaxNode).new(input, i17...index, s17)
                r17.extend(AnyValue2)
              else
                self.index = i17
                r17 = nil
              end
              if r17
                r15 = r17
              else
                self.index = i15
                r15 = nil
              end
            end
            if r15
              s14 << r15
            else
              break
            end
          end
          r14 = SyntaxNode.new(input, i14...index, s14)
          s12 << r14
          if r14
            if input.index("'", index) == index
              r20 = (SyntaxNode).new(input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure("'")
              r20 = nil
            end
            s12 << r20
          end
        end
        if s12.last
          r12 = (RFormation::ConditionAST::String).new(input, i12...index, s12)
          r12.extend(AnyValue3)
        else
          self.index = i12
          r12 = nil
        end
        if r12
          r0 = r12
        else
          i21, s21 = index, []
          if input.index("`", index) == index
            r22 = (SyntaxNode).new(input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("`")
            r22 = nil
          end
          s21 << r22
          if r22
            s23, i23 = [], index
            loop do
              i24 = index
              if input.index(Regexp.new('[^\\\\`]'), index) == index
                r25 = (SyntaxNode).new(input, index...(index + 1))
                @index += 1
              else
                r25 = nil
              end
              if r25
                r24 = r25
              else
                i26, s26 = index, []
                if input.index("\\", index) == index
                  r27 = (SyntaxNode).new(input, index...(index + 1))
                  @index += 1
                else
                  terminal_parse_failure("\\")
                  r27 = nil
                end
                s26 << r27
                if r27
                  if index < input_length
                    r28 = (SyntaxNode).new(input, index...(index + 1))
                    @index += 1
                  else
                    terminal_parse_failure("any character")
                    r28 = nil
                  end
                  s26 << r28
                end
                if s26.last
                  r26 = (SyntaxNode).new(input, i26...index, s26)
                  r26.extend(AnyValue4)
                else
                  self.index = i26
                  r26 = nil
                end
                if r26
                  r24 = r26
                else
                  self.index = i24
                  r24 = nil
                end
              end
              if r24
                s23 << r24
              else
                break
              end
            end
            r23 = SyntaxNode.new(input, i23...index, s23)
            s21 << r23
            if r23
              if input.index("`", index) == index
                r29 = (SyntaxNode).new(input, index...(index + 1))
                @index += 1
              else
                terminal_parse_failure("`")
                r29 = nil
              end
              s21 << r29
            end
          end
          if s21.last
            r21 = (RFormation::ConditionAST::BackString).new(input, i21...index, s21)
            r21.extend(AnyValue5)
          else
            self.index = i21
            r21 = nil
          end
          if r21
            r0 = r21
          else
            self.index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:any_value][start_index] = r0

    return r0
  end

  module Space0
  end

  def _nt_space
    start_index = index
    if node_cache[:space].has_key?(index)
      cached = node_cache[:space][index]
      @index = cached.interval.end if cached
      return cached
    end

    s0, i0 = [], index
    loop do
      i1 = index
      if input.index(Regexp.new('[ \\t\\n\\r\\f]'), index) == index
        r2 = (SyntaxNode).new(input, index...(index + 1))
        @index += 1
      else
        r2 = nil
      end
      if r2
        r1 = r2
      else
        i3, s3 = index, []
        if input.index("#", index) == index
          r4 = (SyntaxNode).new(input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("#")
          r4 = nil
        end
        s3 << r4
        if r4
          s5, i5 = [], index
          loop do
            if input.index(Regexp.new('[^\\n]'), index) == index
              r6 = (SyntaxNode).new(input, index...(index + 1))
              @index += 1
            else
              r6 = nil
            end
            if r6
              s5 << r6
            else
              break
            end
          end
          r5 = SyntaxNode.new(input, i5...index, s5)
          s3 << r5
        end
        if s3.last
          r3 = (SyntaxNode).new(input, i3...index, s3)
          r3.extend(Space0)
        else
          self.index = i3
          r3 = nil
        end
        if r3
          r1 = r3
        else
          self.index = i1
          r1 = nil
        end
      end
      if r1
        s0 << r1
      else
        break
      end
    end
    if s0.empty?
      self.index = i0
      r0 = nil
    else
      r0 = SyntaxNode.new(input, i0...index, s0)
    end

    node_cache[:space][start_index] = r0

    return r0
  end

  def _nt_ospace
    start_index = index
    if node_cache[:ospace].has_key?(index)
      cached = node_cache[:ospace][index]
      @index = cached.interval.end if cached
      return cached
    end

    r1 = _nt_space
    if r1
      r0 = r1
    else
      r0 = SyntaxNode.new(input, index...index)
    end

    node_cache[:ospace][start_index] = r0

    return r0
  end

end

class RFormation::ConditionParser < Treetop::Runtime::CompiledParser
  include RFormation::Condition
end

