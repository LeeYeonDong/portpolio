# ==========================================================
# [완전 수정됨] 하위 폴더 및 내부 파일 일괄 삭제 로직
# ==========================================================
target_dir <- "D:/대학원/portpolio/all_pdfs"

# 1. R 세션이 쥐고 있는 파일 핸들을 강제로 놓도록 가비지 컬렉션 호출
gc()
Sys.sleep(0.5) # OS가 잠금을 해제할 수 있도록 0.5초 대기

# 2. 하위 디렉토리 목록만 정확히 추출 (자기 자신인 target_dir 제외)
all_dirs <- list.dirs(target_dir, full.names = TRUE, recursive = FALSE)
sub_dirs <- all_dirs[all_dirs != target_dir]

# 3. 폴더째로 내부 파일까지 한 번에 강제 삭제
if (length(sub_dirs) > 0) {
  # force = TRUE 옵션을 주어 읽기 전용 속성이 걸려있어도 강제 삭제 유도
  unlink(sub_dirs, recursive = TRUE, force = TRUE)
  cat(sprintf("\n✔ 총 %d개의 batch 하위 폴더 및 내부 파일이 깔끔하게 삭제되었습니다.\n", length(sub_dirs)))
} else {
  cat("\nℹ 삭제할 하위 폴더가 존재하지 않습니다.\n")
}

# ==========================================================
# 1. 필수 패키지 설치 및 로드
# ==========================================================
packages_needed <- c("chromote", "qpdf", "base64enc", "pdftools", "stringr", "dplyr", "tidyr", "purrr")
for (pkg in packages_needed) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# 봇 탐지 회피 및 헤드리스 해제
Sys.setenv(CHROMOTE_HEADLESS = "false")

start_time <- Sys.time()

# ==========================================================
# 2. 경로 및 기본 데이터 설정
# ==========================================================
base_path <- "D:/대학원/portpolio"
dir_all <- file.path(base_path, "all_pdfs")
if(!dir.exists(dir_all)) dir.create(dir_all, recursive = TRUE)

output_csv <- file.path(base_path, "financial_indicators_realtime.csv")

# URL 데이터 로드
url_data <- read.csv(file.path(base_path, "URL_260708df.csv"), stringsAsFactors = FALSE, check.names = FALSE)

# ==========================================================
# 3. 안정성이 강화된 Chromote PDF 저장 함수 (재시도 로직 포함)
# ==========================================================
save_pdf_chromote_with_retry <- function(url, output_file, target_pages, max_retries = 3) {
  if (file.exists(output_file)) {
    cat(sprintf("   이전 작업에서 이미 다운로드 성공: %s (스킵)\n", basename(output_file)))
    return(TRUE)
  }
  
  attempt <- 1
  success <- FALSE
  
  while (attempt <= max_retries && !success) {
    if (attempt > 1) {
      cat(sprintf("   ⚠️ 포트오류 또는 에러로 재시도 중... (%d/%d회차) - 5초 대기\n", attempt, max_retries))
      Sys.sleep(5)
      gc() # 가비지 컬렉션으로 잠긴 포트 해제 유도
    }
    
    b <- NULL
    temp_pdf <- tempfile(fileext = ".pdf")
    
    tryCatch({
      # 세션 초기화 자체를 감싸서 디버깅 포트 오픈 에러 방어
      b <- ChromoteSession$new()
      
      b$Network$setUserAgentOverride(
        userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
      )
      
      b$Page$navigate(url)
      
      wait_time <- round(runif(1, min = 4.5, max = 6), 10)
      cat(sprintf("   ▶ [%s] 접속 중... (%.8f초 대기)\n", basename(output_file), wait_time))
      Sys.sleep(wait_time)
      
      pdf_data <- b$Page$printToPDF()
      writeBin(base64enc::base64decode(pdf_data$data), temp_pdf)
      
      total_pages <- qpdf::pdf_length(temp_pdf)
      pages_to_extract <- intersect(target_pages, 1:total_pages)
      
      if(length(pages_to_extract) > 0) {
        qpdf::pdf_subset(temp_pdf, pages = pages_to_extract, output = output_file)
        cat(sprintf("   ✔ 성공: %s\n", basename(output_file)))
        success <- TRUE
      }
    }, error = function(e) {
      cat(sprintf("   ❌ 시도 %d 실패 (%s): %s\n", attempt, url, e$message))
    }, finally = {
      if (!is.null(b)) {
        try(b$parent$close(), silent = TRUE)
      }
      if (file.exists(temp_pdf)) file.remove(temp_pdf)
    })
    
    attempt <- attempt + 1
  }
  
  return(success)
}

# ==========================================================
# [완전 수정됨] 4. 정규표현식 패턴 및 텍스트 정제 함수 정의
# 줄바꿈(\n) 및 테이블 분리자(|)를 완벽히 통과하도록 [\s\n\|]+ 활용
# 단위를 나타내는 K, M, B, % 기호 추가 매칭 허용
# ==========================================================
regex_patterns <- list(
  `RSI` = "(?i)RSI\\s*\\(14\\)[\\s\\n\\|]+([0-9\\.,]+)",
  `MACD` = "(?i)MACD\\s*\\(12,26\\)[\\s\\n\\|]+([\\-0-9\\.,]+)",
  `ADX` = "(?i)ADX\\s*\\(14\\)[\\s\\n\\|]+([0-9\\.,]+)",
  `STOCH / STOCHRSI` = "(?i)STOCHRSI\\s*\\(14\\)[\\s\\n\\|]+([0-9\\.,]+)|(?i)STOCH\\s*\\(9,6\\)[\\s\\n\\|]+([0-9\\.,]+)",
  `ATR` = "(?i)ATR\\s*\\(14\\)[\\s\\n\\|]+([0-9\\.,]+)",
  
  `ROE` = "(?i)Return on Equity[\\s\\n\\|]+([\\-0-9\\.,]+%?)",
  `ROA` = "(?i)Return on Assets[\\s\\n\\|]+([\\-0-9\\.,]+%?)",
  `EV/EBITDA` = "(?i)EV/EBITDA[\\s\\n\\|]+([\\-0-9\\.,]+|N/A)",
  `Beta` = "(?i)\\bBeta\\b[\\s\\n\\|]+([\\-0-9\\.,]+)",
  `Avg Vol (3m)` = "(?i)Average Vol\\.\\s*\\(3m\\)[\\s\\n\\|]+([0-9\\.,]+[KMBkmb]?)",
  
  `외인소진율` = "외인소진율[\\s\\n\\|]+([0-9\\.,]+%?)",
  `추정 PER` = "추정\\s*PER[\\s\\n\\|]+[0-9]{4}\\.[0-9]{2}\\.?[\\s\\n\\|]+([0-9\\.,]+)배",
  
  `MA1` = "(?:MA1|MAT)[\\s\\n\\|]+([0-9\\.,]+)",
  `MA2` = "MA2[\\s\\n\\|]+([0-9\\.,]+)",
  `MA3` = "MA3[\\s\\n\\|]+([0-9\\.,]+)",
  `MA4` = "MA4[\\s\\n\\|]+([0-9\\.,]+)",
  
  # Naver와 Investing.com의 구조적 차이 병렬 매칭 (Naver의 결산일 2026.03 패턴 무시)
  `PER` = "(?i)P/E Ratio[\\s\\n\\|]+([\\-0-9\\.,]+|N/A)|PER[\\s\\n]+[0-9]{4}\\.[0-9]{2}\\.?[\\s\\n\\|]+([0-9\\.,]+|N/A)배?",
  `EPS` = "(?i)EPS[\\s\\n\\|]+([\\-0-9\\.,]+|N/A)|EPS[\\s\\n]+[0-9]{4}\\.[0-9]{2}\\.?[\\s\\n\\|]+([\\-0-9\\.,]+|N/A)",
  `PBR` = "(?i)Price/Book[\\s\\n\\|]+([0-9\\.,]+|N/A)|PBR[\\s\\n]+[0-9]{4}\\.[0-9]{2}\\.?[\\s\\n\\|]+([0-9\\.,]+|N/A)배?",
  `Volume` = "(?i)\\bVolume\\b[\\s\\n\\|]+([0-9\\.,]+[KMBkmb]?)|거래량[\\s\\n\\|]+([0-9\\.,]+)[\\s\\n\\|]+대금",
  
  `Day's Range` = "(?i)Day's Range[\\s\\n\\|]+([0-9\\.,]+\\s*\\-?\\s*[0-9\\.,]+)",
  `52-Week Range` = "(?i)52\\s*wk Range[\\s\\n\\|]+([0-9\\.,]+\\s*\\-?\\s*[0-9\\.,]+)",
  `Bid / Ask` = "(?i)Bid\\s*/\\s*Ask[\\s\\n\\|]+([0-9\\.,]+\\s*/\\s*[0-9\\.,]+)",
  `괴리율` = "괴리율[\\s\\n\\|]+([\\-0-9\\.,]+%?)",
  `EPS Growth` = "(?i)EPS Growth[\\a-zA-Z\\s]*?[\\s\\n\\|]+([\\-0-9\\.,]+%?)",
  
  `BPS` = "(?i)Book Value / Share[\\s\\n\\|]+([0-9\\.,]+|N/A)|BPS[\\s\\n]+[0-9]{4}\\.[0-9]{2}\\.?[\\s\\n\\|]+([0-9\\.,]+|N/A)",
  `Gross Profit Margin` = "(?i)Gross Profit Margin[\\s\\n\\|]+([\\-0-9\\.,]+%?)",
  `NAV` = "(?i)NAV[\\s\\n\\|]+([0-9\\.,]+)",
  `Expense Ratio` = "(?i)Expense Ratio[\\s\\n\\|]+([0-9\\.,]+%?)|총보수[\\s\\n\\|]+([0-9\\.,]+%?)",
  
  `Dividend Yield` = "(?i)Dividend \\(Yield\\)[\\s\\n\\|]+[0-9\\.,]+\\s*\\(([0-9\\.,]+%?|N/A)\\)|배당수익률[\\s\\n]+[0-9]{4}\\.[0-9]{2}\\.?[\\s\\n\\|]+([0-9\\.,]+%?|N/A)",
  `Dividends (TTM)` = "(?i)Dividends\\s*\\(TTM\\)[\\s\\n\\|]+([0-9\\.,]+)"
)

extract_val <- function(text, pattern) {
  if (is.na(text) || text == "") return(NA)
  m <- str_match(text, pattern)
  if (!is.na(m[1, 1])) return(na.omit(m[1, -1])[1]) # |(OR) 정규식에서 잡힌 그룹 중 NA가 아닌 첫 번째 값만 반환
  return(NA)
}

resolve_conflict <- function(val_inv, val_naver) {
  if (is.na(val_inv) && is.na(val_naver)) return(NA)
  if (is.na(val_inv)) return(val_naver)
  if (is.na(val_naver)) return(val_inv)
  if (val_inv == val_naver) return(val_inv)
  return(sprintf("Investing: %s / Naver: %s", val_inv, val_naver))
}

# ==========================================================
# 5. 메인 루프 (다운로드 -> 즉시 추출 -> 실시간 CSV 누적 전치)
# ==========================================================
cat("=== 실시간 수집 및 교차 데이터 분석 시작 ===\n")

batch_size <- 3
master_extracted_data <- data.frame() 

for (i in 1:nrow(url_data)) {
  
  batch_num <- ceiling(i / batch_size)
  start_idx <- (batch_num - 1) * batch_size + 1
  end_idx <- min(batch_num * batch_size, nrow(url_data))
  start_id <- sprintf("%02d", as.numeric(url_data$id[start_idx]))
  end_id <- sprintf("%02d", as.numeric(url_data$id[end_idx]))
  batch_names <- paste(url_data$Name[start_idx:end_idx], collapse = "_")
  folder_name <- sprintf("batch_%02d_(id_%s-%s)__(%s)", batch_num, start_id, end_id, batch_names)
  batch_dir <- file.path(dir_all, folder_name)
  if(!dir.exists(batch_dir)) dir.create(batch_dir, recursive = TRUE)
  
  stock_name <- url_data$Name[i]
  stock_id_raw <- as.character(url_data$id[i]) 
  
  cat(sprintf("\n--- [%d/%d번째 종목(%s) 처리 시작] ---\n", i, nrow(url_data), stock_name))
  
  url_naver <- url_data$naver_stock[i]
  url_inv1  <- url_data[["investing 1"]][i]
  url_inv2  <- url_data[["investing 2"]][i]
  
  path_naver <- ""
  path_inv1  <- ""
  path_tech  <- ""
  
  if (!is.na(url_naver) && url_naver != "") {
    stock_id_naver <- basename(sub("/price/?$", "", url_naver))
    path_naver <- file.path(batch_dir, sprintf("naver_%s.pdf", stock_id_naver))
    cat("  순서 1: Naver 다운로드...\n")
    save_pdf_chromote_with_retry(url_naver, path_naver, 1)
  }
  
  if (!is.na(url_inv1) && url_inv1 != "") {
    stock_id_inv1 <- basename(url_inv1)
    path_inv1 <- file.path(batch_dir, sprintf("inv1_%s.pdf", stock_id_inv1))
    cat("  순서 2: Investing 1 다운로드...\n")
    save_pdf_chromote_with_retry(url_inv1, path_inv1, 1:2)
  }
  
  if (!is.na(url_inv2) && url_inv2 != "") {
    stock_id_inv2 <- basename(url_inv2)
    path_tech <- file.path(batch_dir, sprintf("inv2_%s.pdf", stock_id_inv2))
    cat("  순서 3: Investing 2 다운로드...\n")
    save_pdf_chromote_with_retry(url_inv2, path_tech, 1:2)
  }
  
  # ==========================================================
  # 실시간 지표 추출 파트 (종목이 끝날 때마다 즉시 텍스트화 분석)
  # ==========================================================
  cat("  -> 다운로드 프로세스 종료. 실시간 지표 분석 및 파싱 진입...\n")
  
  get_text_safe <- function(file_path) {
    if (file_path != "" && file.exists(file_path)) {
      return(tryCatch(paste(pdftools::pdf_text(file_path), collapse = " \n "), error = function(e) ""))
    }
    return("")
  }
  
  text_naver <- get_text_safe(path_naver)
  text_inv1  <- get_text_safe(path_inv1)
  text_tech  <- get_text_safe(path_tech)
  
  current_stock_res <- list(Stock_ID = stock_name)
  
  # 1. 시간축 고정 (Technical 문서 활용)
  current_stock_res[["RSI (14d)"]] <- extract_val(text_tech, regex_patterns$`RSI`)
  current_stock_res[["MACD (12,26)"]] <- extract_val(text_tech, regex_patterns$`MACD`)
  current_stock_res[["ADX (14)"]] <- extract_val(text_tech, regex_patterns$`ADX`)
  current_stock_res[["STOCH / STOCHRSI"]] <- extract_val(text_tech, regex_patterns$`STOCH / STOCHRSI`)
  current_stock_res[["ATR (14)"]] <- extract_val(text_tech, regex_patterns$`ATR`)
  
  # 2. 펀더멘털 및 환경 지표 (inv1 활용)
  current_stock_res[["ROE (자기자본이익률)"]] <- extract_val(text_inv1, regex_patterns$`ROE`)
  current_stock_res[["ROA (총자산이익률)"]] <- extract_val(text_inv1, regex_patterns$`ROA`)
  current_stock_res[["EV/EBITDA"]] <- extract_val(text_inv1, regex_patterns$`EV/EBITDA`)
  current_stock_res[["Beta (베타)"]] <- extract_val(text_inv1, regex_patterns$`Beta`)
  current_stock_res[["Average Vol. (3m)"]] <- extract_val(text_inv1, regex_patterns$`Avg Vol (3m)`)
  
  # 3. 국내 전용 지표 (Naver 활용)
  current_stock_res[["외인소진율"]] <- extract_val(text_naver, regex_patterns$`외인소진율`)
  current_stock_res[["추정 PER"]] <- extract_val(text_naver, regex_patterns$`추정 PER`)
  
  current_stock_res[["MA1"]] <- extract_val(text_naver, regex_patterns$`MA1`)
  current_stock_res[["MA2"]] <- extract_val(text_naver, regex_patterns$`MA2`)
  current_stock_res[["MA3"]] <- extract_val(text_naver, regex_patterns$`MA3`)
  current_stock_res[["MA4"]] <- extract_val(text_naver, regex_patterns$`MA4`)
  
  # 4. 범용 데이터 검증 및 충돌 해결 병기
  general_indicators <- c("PER", "EPS", "PBR", "Volume", "Day's Range", "52-Week Range", 
                          "Bid / Ask", "괴리율", "EPS Growth", "BPS", "Gross Profit Margin", 
                          "NAV", "Expense Ratio", "Dividend Yield", "Dividends (TTM)")
  
  for(ind in general_indicators) {
    val_in_inv <- extract_val(text_inv1, regex_patterns[[ind]])
    val_in_naver <- extract_val(text_naver, regex_patterns[[ind]])
    current_stock_res[[ind]] <- resolve_conflict(val_in_inv, val_in_naver)
  }
  
  stock_df <- as.data.frame(current_stock_res, stringsAsFactors = FALSE)
  master_extracted_data <- bind_rows(master_extracted_data, stock_df)
  
  # ==========================================================
  # 전치(Transpose) 후 CSV 덮어쓰기 (실시간 저장소 보존)
  # ==========================================================
  realtime_transposed_csv <- master_extracted_data %>%
    pivot_longer(cols = -Stock_ID, names_to = "Indicator", values_to = "Value") %>%
    pivot_wider(names_from = Stock_ID, values_from = Value)
  
  write.csv(realtime_transposed_csv, 
            file = file.path(dir_all, "financial_indicators_realtime.csv"), row.names = FALSE, fileEncoding = "CP949")
  cat(sprintf("  💾 [실시간 동기화 완료] 현재 %d개 종목이 누적 저장되었습니다.\n", nrow(master_extracted_data)))
}

cat("\n=== 모든 대용량 크롤링 및 실시간 데이터 구조화 작업이 완벽하게 종료되었습니다! ===\n")

end_time <- Sys.time()
end_time - start_time
