package com.gittowork.global.deserializer;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gittowork.domain.github.model.sonar.SonarResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ConditionListDeserializer extends JsonDeserializer<List<SonarResponse.Condition>> {
    @Override
    public List<SonarResponse.Condition> deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        JsonToken token = p.getCurrentToken();
        if (token == JsonToken.VALUE_FALSE) {
            // 값이 false이면 빈 리스트 반환
            return new ArrayList<>();
        }
        // 그렇지 않으면 정상적으로 리스트로 역직렬화
        ObjectMapper mapper = (ObjectMapper) p.getCodec();
        return mapper.readValue(p, new TypeReference<List<SonarResponse.Condition>>() {});
    }
}
