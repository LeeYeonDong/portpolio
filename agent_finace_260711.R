# ==============================================================================
# [V5] RStudio + Jules CLI 통합 투자 에이전트 (비용 제로화 & 다중 세션 자동화)
# ==============================================================================
library(jsonlite)
library(rmarkdown)

start_time_finance <- Sys.time()

# ------------------------------------------------------------------------------
# [환경 설정]
# ------------------------------------------------------------------------------
BASE_DIR      <- "D:/대학원/portpolio"
PATH_CSV      <- file.path(BASE_DIR, "all_pdfs", "financial_indicators_realtime.csv")
PATH_R_SCRIPT <- "D:/Not_Pretence/pdf_finace_260617.R"

# 👇 실행 전 매번 업데이트해야 하는 사용자 메타 데이터
USER_CASH_TOSS <- "3,000,000원 + $0($0 원화 환전 가능)"
USER_LIMIT_ISA <- "올해 한도 마감됨."
USER_LIMIT_PEN <- "올해 한도 마감됨. 계좌 현금 납입은 가능 세액은 내년 납입분으로 공제 가능"

MACRO_FEAR_GREED <- 49
MACRO_USD_KRW_NOW <- 1499.15
MACRO_USD_KRW_AVG <- 1455.25

# ------------------------------------------------------------------------------
# 1단계: R 크롤러 엔진 구동 및 데이터 로드 (인코딩/크래시 픽스)
# ------------------------------------------------------------------------------
cat("=== 🔄 1단계: 로컬 크롤러 구동 및 실시간 금융 지표 데이터 연동 ===\n")
if(!file.exists(PATH_R_SCRIPT)) stop("❌ 스크립트 파일을 찾을 수 없습니다.")

source(PATH_R_SCRIPT, encoding = "UTF-8")

if(!file.exists(PATH_CSV)) stop("❌ 크롤링된 지표 CSV 파일이 존재하지 않습니다.")

# 💡 Chromote 타임아웃 에러 방어 및 메모리 정리 (윈도우 전용 찌꺼기 크롬 강제 종료)
# 크롤러가 완료된 후 발생하는 Promise 타임아웃 텍스트를 무시하고 넘어가기 위한 조치입니다.
system("taskkill /F /IM chrome.exe /T 2>nul", ignore.stdout = TRUE, ignore.stderr = TRUE)

# 🚨 [버그 수정]: CSV 구조 붕괴(0행) 및 한글 깨짐 동시 해결
# 윈도우(CP949) 환경에서 생성된 CSV를 자연스럽게 로드하여 열(Column) 밀림 현상을 방지합니다.
indicator_df <- read.csv(PATH_CSV, check.names = FALSE, fileEncoding = "CP949", stringsAsFactors = FALSE)

View(indicator_df)

# JSON으로 변환할 때 한글이 유니코드(\u...)로 깨지는 것을 원천 차단
indicator_text <- jsonlite::toJSON(indicator_df, pretty = TRUE, force = TRUE, auto_unbox = TRUE)
cat("   ✔ 실시간 금융 지표 구조화 및 인코딩 동기화 완료!\n\n")

# ------------------------------------------------------------------------------
# 2단계: Jules 분석용 실시간 데이터 스냅샷 저장
# ------------------------------------------------------------------------------
cat("=== 💾 2단계: Jules 가상 VM이 읽을 최신 실시간 데이터 스냅샷 저장 ===\n")

meta_data_text <- sprintf(
  "- 투자 가능 현금: 토스증권 %s\n- ISA계좌: %s\n- 연금계좌: %s\n- Fear & Greed Index: %d\n- 환율: 현재 %.2f / 1년평균 %.2f",
  USER_CASH_TOSS, USER_LIMIT_ISA, USER_LIMIT_PEN, MACRO_FEAR_GREED, MACRO_USD_KRW_NOW, MACRO_USD_KRW_AVG
)

# 💡 [핵심] R에서 프롬프트를 빼고 가벼운 데이터만 전달. OCR은 JULES.md 지시를 따르도록 유도.
realtime_payload <- paste0(
  "## [실시간 금융 데이터 현황]\n\n",
  "### 1) 보유 종목 현황 (OCR)\n", 
  "👉 JULES.md의 지침에 따라 'portpolio_image/' 폴더 내 이미지를 직접 판독하여 사용하라.\n\n",
  "### 2) 지표 현황 (크롤링 결과)\n", indicator_text, "\n\n",
  "### 3) 계좌 제약 및 매크로 변수\n", meta_data_text
)

output_file <- file.path(BASE_DIR, "realtime_snapshot.txt")
writeLines(realtime_payload, output_file, useBytes = TRUE)
cat("   ✔ 'realtime_snapshot.txt' 로컬 저장 완료.\n\n")

# ------------------------------------------------------------------------------
# 3단계: [자동화] 최신 스냅샷 깃허브 자동 업로드
# ------------------------------------------------------------------------------
cat("=== 🤖 3단계: R 자동화 - 깃허브에 실시간 스냅샷 동기화 중... ===\n")
tryCatch({
  system("git add realtime_snapshot.txt")
  system("git commit -m \"Auto-update realtime snapshot for Jules\"")
  system("git push origin main")
  cat("   ✔ 깃허브 자동 업로드 완료!\n\n")
}, error = function(e) { cat("   ❌ 깃허브 업로드 중 오류 발생.\n") })



# ------------------------------------------------------------------------------
# 4단계: [다중 세션] Chat 1 & Chat 2 쌍둥이 병렬 분석 지시 (260708 Parity)
# ------------------------------------------------------------------------------
cat("=== 🚀 4단계: Jules 클라우드 VM에 Chat 1 & Chat 2 쌍둥이 병렬 가동 ===\n")

# 💡 [핵심 복구]: 260708 버전과 동일하게 두 에이전트에게 100% 똑같은 통합 분석을 지시합니다.
prompt_chat1 <- '내 저장소의 realtime_snapshot.txt를 읽고, JULES.md에 명시된 V3.1 룰북과 7단계 파이프라인 분석 프로토콜을 단 한 치의 오차도 없이 100% 준수하여 전체 자산을 진단해 줘. 결과를 Chat_1_Report.md 파일로 작성해서 내 저장소에 올려줘.'

prompt_chat2 <- '내 저장소의 realtime_snapshot.txt를 읽고, JULES.md에 명시된 V3.1 룰북과 7단계 파이프라인 분석 프로토콜을 단 한 치의 오차도 없이 100% 준수하여 전체 자산을 진단해 줘. 결과를 Chat_2_Report.md 파일로 작성해서 내 저장소에 올려줘.'

system(sprintf('jules new "%s"', prompt_chat1))
system(sprintf('jules new "%s"', prompt_chat2))
cat("   ✔ Chat 1과 Chat 2 독립 쌍둥이 세션 생성 완료. 클라우드 연산을 시작합니다.\n\n")


# ------------------------------------------------------------------------------
# 5단계: [폴링] 보고서 수신 대기 (Git Pull)
# ------------------------------------------------------------------------------
cat("=== 📥 5단계: 쌍둥이 독립 분석 보고서 수신 대기 (Git Pull) ===\n")
file_chat1 <- file.path(BASE_DIR, "Chat_1_Report.md")
file_chat2 <- file.path(BASE_DIR, "Chat_2_Report.md")

if(file.exists(file_chat1)) file.remove(file_chat1)
if(file.exists(file_chat2)) file.remove(file_chat2)

wait_count <- 0
success_twins <- FALSE
while(wait_count < 15) {
  Sys.sleep(60)
  wait_count <- wait_count + 1
  cat(sprintf("   🔄 [%d분 경과] Chat 1/2 보고서 수신 확인 중...\n", wait_count))
  system("git pull origin main", ignore.stdout = TRUE, ignore.stderr = TRUE)
  if(file.exists(file_chat1) && file.exists(file_chat2)) {
    success_twins <- TRUE
    break
  }
}
if(!success_twins) stop("❌ 15분 초과: 클라우드 지연. 수동으로 git pull 진행 요망.")
cat("   ✔ Chat 1 & Chat 2 쌍둥이 보고서 수신 완료!\n\n")


# ------------------------------------------------------------------------------
# 6단계: Judge (판사 레이어) 최종 조율 지시 (260708 Parity)
# ------------------------------------------------------------------------------
cat("=== ⚖️ 6단계: Judge 판사 레이어 가동 및 최종 통합안 도출 지시 ===\n")
prompt_judge <- '방금 저장소에 업로드된 Chat_1_Report.md와 Chat_2_Report.md를 꼼꼼히 대조해 줘. 최고투자책임자(CIO) 관점에서 두 에이전트의 5단계 Execution Matrix를 교차 검증하고, 오차가 있다면 V3.1 룰북 예외 규칙에 가장 부합하는 안전한 방향으로 싱크(Sync)를 맞춰 최종 합의 조언서를 Final_Execution_Report_Debate.md 로 작성해서 내 저장소에 올려줘.'

system(sprintf('jules new "%s"', prompt_judge))


# ------------------------------------------------------------------------------
# 7단계: [최종 폴링 및 시각화] 판결문 수신 및 HTML 렌더링
# ------------------------------------------------------------------------------
cat("=== 📥 7단계: 최종 판결문 수신 대기 및 HTML 시각화 (Parity 복구) ===\n")
file_final <- file.path(BASE_DIR, "Final_Execution_Report_Debate.md")
if(file.exists(file_final)) file.remove(file_final)

wait_count_judge <- 0
success_judge <- FALSE
while(wait_count_judge < 10) {
  Sys.sleep(60)
  wait_count_judge <- wait_count_judge + 1
  cat(sprintf("   🔄 [%d분 경과] Judge 합의문 수신 확인 중...\n", wait_count_judge))
  system("git pull origin main", ignore.stdout = TRUE, ignore.stderr = TRUE)
  if(file.exists(file_final)) {
    success_judge <- TRUE
    break
  }
}

if(success_judge) {
  cat("   ✔ 최종 합의문 수신 완료! HTML 디자인 렌더링을 시작합니다...\n")
  output_html_path <- file.path(BASE_DIR, "Final_Execution_Report_Debate.html")
  
  # 🎯 [버그 수정]: file_a, file_b 오타를 file_chat1, file_chat2로 매칭 복구
  combined_md <- paste0(
    "# 📈 실시간 자산 배분 조언서 (Jules 미국주식/ETF 쌍둥이 크로스 체크)\n\n",
    "## 📂 Chat 1 실행창 분석 결과\n", paste(readLines(file_chat1, encoding="UTF-8"), collapse="\n"), "\n\n---\n\n",
    "## 📂 Chat 2 실행창 분석 결과\n", paste(readLines(file_chat2, encoding="UTF-8"), collapse="\n"), "\n\n---\n\n",
    "## ⚖️ Judge Chat 최종 통합 합의문\n", paste(readLines(file_final, encoding="UTF-8"), collapse="\n")
  )
  
  temp_md <- file.path(BASE_DIR, "temp_combined.md")
  writeLines(combined_md, temp_md, useBytes = TRUE)
  
  render(input = temp_md,
         output_format = html_document(theme = "flatly", highlight = "tango", toc = TRUE, toc_float = TRUE),
         output_file = output_html_path, quiet = TRUE)
  file.remove(temp_md)
  
  cat("\n========================================================\n")
  cat("🎉 [Jules 완벽 연동 - 다중 세션 파이프라인 및 HTML 생성 완결] \n")
  cat(sprintf("🌐 HTML 웹페이지 주소: %s\n", output_html_path))
  cat("========================================================\n")
} else {
  cat("\n   ❌ Judge 처리 지연. 잠시 후 수동으로 확인하세요.\n")
}

cat(sprintf("\n총 소요 시간: %s\n", round(Sys.time() - start_time_finance, 2)))