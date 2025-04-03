package com.gittowork.domain.fortune.service;

import com.gittowork.domain.fortune.dto.request.InsertFortuneInfoRequest;
import com.gittowork.domain.fortune.dto.response.GetFortuneInfoResponse;
import com.gittowork.domain.fortune.entity.FortuneInfo;
import com.gittowork.domain.fortune.model.SajuResult;
import com.gittowork.domain.fortune.model.SolarTerm;
import com.gittowork.domain.fortune.repository.FortuneInfoRepository;
import com.gittowork.domain.user.dto.response.MessageOnlyResponse;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.FortuneInfoNotFoundException;
import com.gittowork.global.exception.UserNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FortuneService {

    private final FortuneInfoRepository fortuneInfoRepository;
    private final UserRepository userRepository;

    private static final String[] HEAVENLY_STEMS = {"갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"};
    private static final String[] EARTHLY_BRANCHES = {"자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"};

    private static final LocalDate BASE_DATE = LocalDate.of(1900, 1, 31);

    private static final List<SolarTerm> SOLAR_TERMS = Arrays.asList(
            new SolarTerm(1,  5,  "축"),
            new SolarTerm(2,  4,  "인"),
            new SolarTerm(3,  6,  "묘"),
            new SolarTerm(4,  5,  "진"),
            new SolarTerm(5,  6,  "사"),
            new SolarTerm(6,  5,  "오"),
            new SolarTerm(7,  7,  "미"),
            new SolarTerm(8,  8,  "신"),
            new SolarTerm(9,  8,  "유"),
            new SolarTerm(10, 8,  "술"),
            new SolarTerm(11, 7,  "해"),
            new SolarTerm(12, 7,  "자")
    );

    @Transactional
    public MessageOnlyResponse insertFortuneInfo(InsertFortuneInfoRequest insertFortuneInfoRequest) {
        User user = getUser();

        FortuneInfo fortuneInfo = FortuneInfo.builder()
                .user(user)
                .birthDt(LocalDate.parse(insertFortuneInfoRequest.getBirthDt()))
                .sex(insertFortuneInfoRequest.getSex())
                .time(LocalTime.parse(insertFortuneInfoRequest.getBirthTm(), DateTimeFormatter.ofPattern("HH:mm")))
                .build();

        fortuneInfoRepository.save(fortuneInfo);

        return MessageOnlyResponse.builder()
                .message("오늘의 운세 사용자 정보가 성공적으로 저장되었슴니다.")
                .build();
    }

    @Transactional(readOnly = true)
    public GetFortuneInfoResponse getFortuneInfo() {
        User user = getUser();

        FortuneInfo fortuneInfo = fortuneInfoRepository.findByUser(user)
                .orElseThrow(() -> new FortuneInfoNotFoundException("Fortune info not found"));

        return GetFortuneInfoResponse.builder()
                .birthDt(fortuneInfo.getBirthDt().toString())
                .sex(fortuneInfo.getSex())
                .birthTm(fortuneInfo.getTime().toString())
                .build();
    }



    private User getUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String userName = authentication.getName();

        return userRepository.findByGithubName(userName)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
    }

    private SajuResult calculateSaju(LocalDateTime birthDateTime) {

        int year = birthDateTime.getYear();
        int yearStemIndex = (year - 4) % 10;
        int yearBranchIndex = (year - 4) % 12;
        String yearPillar = HEAVENLY_STEMS[yearStemIndex] + EARTHLY_BRANCHES[yearBranchIndex];

        String monthBranch = getMonthBranchBySolarTerm(birthDateTime.toLocalDate());
        int monthOrder = getBranchOrder(monthBranch);
        int monthStemIndex = (yearStemIndex * 2 + monthOrder + 1) % 10;
        String monthStem = HEAVENLY_STEMS[monthStemIndex];
        String monthPillar = monthStem + monthBranch;

        LocalDate birthDate = birthDateTime.toLocalDate();
        long daysBetween = ChronoUnit.DAYS.between(BASE_DATE, birthDate);
        int dayIndex = (int) ((daysBetween % 60 + 60) % 60);
        int dayStemIndex = dayIndex % 10;
        int dayBranchIndex = dayIndex % 12;
        String dayPillar = HEAVENLY_STEMS[dayStemIndex] + EARTHLY_BRANCHES[dayBranchIndex];

        String hourPillar = getHourPillar(birthDateTime, dayStemIndex);

        return SajuResult.builder()
                .yearPillar(yearPillar)
                .monthPillar(monthPillar)
                .dayPillar(dayPillar)
                .hourPillar(hourPillar)
                .build();
    }

    private static String getHourPillar(LocalDateTime birthDateTime, int dayStemIndex) {
        int birthHour = birthDateTime.getHour();
        int birthMinute = birthDateTime.getMinute();

        int totalMinutes = birthHour * 60 + birthMinute;

        int adjustedMinutes = totalMinutes - 23 * 60;
        if (adjustedMinutes < 0) {
            adjustedMinutes += 1440;
        }

        double branchIndexDecimal = (double) adjustedMinutes / 120.0;
        int hourBranchIndex = ((int) Math.floor(branchIndexDecimal)) % 12;
        String hourBranch = EARTHLY_BRANCHES[hourBranchIndex];

        double segmentFraction = branchIndexDecimal - Math.floor(branchIndexDecimal);
        int halfHourOffset = (segmentFraction >= 0.5) ? 1 : 0;

        int hourStemIndex = ((dayStemIndex % 5) * 2 + hourBranchIndex + halfHourOffset) % 10;
        String hourStem = HEAVENLY_STEMS[hourStemIndex];

        return hourStem + hourBranch;
    }

    private String getMonthBranch(int month) {
        return switch (month) {
            case 1 -> "인";
            case 2 -> "묘";
            case 3 -> "진";
            case 4 -> "사";
            case 5 -> "오";
            case 6 -> "미";
            case 7 -> "신";
            case 8 -> "유";
            case 9 -> "술";
            case 10 -> "해";
            case 11 -> "자";
            case 12 -> "축";
            default -> throw new IllegalArgumentException("Invalid month: " + month);
        };
    }

    private String getMonthBranchBySolarTerm(LocalDate birthDate) {
        int year = birthDate.getYear();

        List<SolarTerm> currentYearTerms = SOLAR_TERMS.stream()
                .sorted(Comparator.comparing(term -> term.getDate(year))) // 월/일 순 정렬
                .toList();

        SolarTerm matchedTerm = null;
        for (SolarTerm term : currentYearTerms) {
            LocalDate termDate = term.getDate(year);
            if (!birthDate.isBefore(termDate)) {
                matchedTerm = term;
            } else {
                break;
            }
        }

        if (matchedTerm == null) {
            int prevYear = year - 1;
            List<SolarTerm> previousYearTerms = SOLAR_TERMS.stream()
                    .sorted(Comparator.comparing(term -> term.getDate(prevYear)))
                    .toList();
            matchedTerm = previousYearTerms.get(previousYearTerms.size() - 1);
        }

        return matchedTerm.getBranch();
    }

    private int getBranchOrder(String branch) {
        for (int i = 0; i < EARTHLY_BRANCHES.length; i++) {
            if (EARTHLY_BRANCHES[i].equals(branch)) {
                return i;
            }
        }
        return 0;
    }

}
