import java.util.HashMap;
import java.util.HashSet;
import java.util.Arrays;
import java.util.Calendar;
import java.text.SimpleDateFormat;

Table table;
HashMap<String, Integer> colors = new HashMap<String, Integer>();
String[] dates;

void setup() {
  size(800, 800);
  table = loadTable("November_Activities_Rounded_CLEANED.csv", "header");
  println("Rows loaded: " + table.getRowCount());

  // Define colors
  colors.put("Sleep", color(66, 135, 245));        // Blue
  colors.put("Work", color(255, 180, 0));          // Orange
  colors.put("Exercise", color(50, 200, 50));      // Green
  colors.put("Hobbies", color(255, 100, 100));     // Red
  colors.put("Entertainment", color(180, 0, 255)); // Purple

  // Collect unique dates
  HashSet<String> dateSet = new HashSet<String>();
  for (TableRow row : table.rows()) {
    dateSet.add(trim(row.getString("Date")));
  }

  dates = dateSet.toArray(new String[0]);
  Arrays.sort(dates);
  println("Unique dates found: " + dates.length);

  noLoop();
  drawAllDays();
}

void drawAllDays() {
  background(255);
  textAlign(CENTER, CENTER);
  textSize(8);

  // Draw legend top-right
  drawLegendKey(width - 180, 10);

  // Weekday headers
  String[] weekdays = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
  fill(0);
  textSize(10);
  for (int i = 0; i < weekdays.length; i++) {
    float x = map(i, 0, 7, 60, width - 60);
    text(weekdays[i], x, 50);
  }

  // Layout
  int cols = 7;
  float marginX = 50;
  float marginY = 80;
  float gridW = width - marginX * 2;
  float gridH = height - marginY - 150;
  float cellW = gridW / cols;
  float cellH = gridH / 5.0;
  float r = min(cellW, cellH) * 0.35;

  // Get weekday offset for first date
  int offset = weekdayIndex(dates[0]);

  int dayCount = dates.length;
  int dayIdx = 0;

  // Loop through all possible 35 calendar cells (5 weeks × 7 days)
  for (int i = 0; i < 35; i++) {
    int row = i / cols;
    int col = i % cols;

    if (i >= offset && dayIdx < dayCount) {
      float x = marginX + cellW * (col + 0.5);
      float y = marginY + cellH * (row + 0.5);
      drawDayClock(dates[dayIdx], x, y, r);
      dayIdx++;
    }
  }

  // Draw small hourly demo clock in bottom-right corner
  drawDemoClock(width - 90, height - 90, 40);
}

// ------------------------
// CLOCK FUNCTIONS
// ------------------------

void drawDayClock(String date, float cx, float cy, float r) {
  float rOuter = r;
  float rInner = rOuter * 0.7;

  String dominant = getDominantCategoryIncludingFilled(date);
  color dominantCol = getColor(dominant);

  // Outer circle
  strokeWeight(3);
  stroke(dominantCol);
  noFill();
  ellipse(cx, cy, rOuter * 2, rOuter * 2);

  // Hour segments
  strokeWeight(1.3);
  for (int h = 0; h < 24; h++) {
    String cat = getCategoryForHour(date, h);
    if (cat == null || cat.equals("")) {
      if (h < 12) cat = "Work";
      else cat = "Entertainment";
    }

    stroke(getColor(cat));
    float ang = map(h, 0, 24, -HALF_PI, TWO_PI - HALF_PI);
    float x1 = cx + cos(ang) * rInner;
    float y1 = cy + sin(ang) * rInner;
    float x2 = cx + cos(ang) * rOuter;
    float y2 = cy + sin(ang) * rOuter;
    line(x1, y1, x2, y2);
  }

  fill(0);
  noStroke();
  textSize(7);
  text(date, cx, cy + rOuter + 7);
}

void drawDemoClock(float cx, float cy, float r) {
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(7);
  stroke(0);
  strokeWeight(1);
  noFill();
  ellipse(cx, cy, r * 2, r * 2);

  // Draw each hour tick + label
  for (int h = 0; h < 24; h++) {
    float ang = map(h, 0, 24, -HALF_PI, TWO_PI - HALF_PI);
    float x1 = cx + cos(ang) * (r * 0.8);
    float y1 = cy + sin(ang) * (r * 0.8);
    float x2 = cx + cos(ang) * r;
    float y2 = cy + sin(ang) * r;
    line(x1, y1, x2, y2);

    // Label each hour
    float tx = cx + cos(ang) * (r + 10);
    float ty = cy + sin(ang) * (r + 10);
    text(h + "h", tx, ty);
  }

  textAlign(CENTER);
  textSize(8);
  text("Demo Clock", cx, cy + r + 18);
}

// ------------------------
// SUPPORT FUNCTIONS
// ------------------------

String getDominantCategoryIncludingFilled(String date) {
  HashMap<String, Float> hoursByCat = new HashMap<String, Float>();
  for (TableRow row : table.rows()) {
    if (!trim(row.getString("Date")).equals(date)) continue;
    String cat = trim(row.getString("Category"));
    int s = parseHour(row.getString("Start Time"));
    int e = parseHour(row.getString("End Time"));
    String rawEnd = trim(row.getString("End Time"));
    if (e == 0 && !rawEnd.equals("00:00")) e = 24;
    if (e < s) e += 24;
    float dur = e - s;
    hoursByCat.put(cat, hoursByCat.getOrDefault(cat, 0.0) + dur);
  }

  float totalRecorded = 0;
  for (float h : hoursByCat.values()) totalRecorded += h;
  if (totalRecorded < 24) {
    float unrec = 24 - totalRecorded;
    hoursByCat.put("Work", hoursByCat.getOrDefault("Work", 0.0) + unrec / 2.0);
    hoursByCat.put("Entertainment", hoursByCat.getOrDefault("Entertainment", 0.0) + unrec / 2.0);
  }

  String bestCat = "";
  float bestHours = -1;
  for (String c : hoursByCat.keySet()) {
    float h = hoursByCat.get(c);
    if (h > bestHours) {
      bestHours = h;
      bestCat = c;
    }
  }
  return bestCat;
}

String getCategoryForHour(String date, int hour) {
  for (TableRow row : table.rows()) {
    if (!trim(row.getString("Date")).equals(date)) continue;
    int s = parseHour(row.getString("Start Time"));
    int e = parseHour(row.getString("End Time"));
    String rawEnd = trim(row.getString("End Time"));
    if (e == 0 && !rawEnd.equals("00:00")) e = 24;
    if (e < s) e += 24;
    int h = hour;
    if (h < s) h += 24;
    if (h >= s && h < e) return trim(row.getString("Category"));
  }
  return "";
}

int parseHour(String t) {
  if (t == null || t.equals("")) return 0;
  t = trim(t).replaceAll("[^0-9:]", "");
  if (t.indexOf(':') >= 0) t = split(t, ':')[0];
  if (t.equals("")) return 0;
  return constrain(int(t), 0, 24);
}

color getColor(String cat) {
  if (cat == null || cat.equals("")) return color(220);
  Integer c = colors.get(cat);
  if (c == null) {
    for (String key : colors.keySet())
      if (key.equalsIgnoreCase(cat)) return colors.get(key);
    return color(180);
  }
  return c;
}

// Monday = 0, Sunday = 6
int weekdayIndex(String dateStr) {
  try {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    Calendar cal = Calendar.getInstance();
    cal.setTime(sdf.parse(dateStr));
    int day = cal.get(Calendar.DAY_OF_WEEK); // 1=Sunday
    int idx = (day + 5) % 7; // shift so Monday=0
    return idx;
  } 
  catch (Exception e) {
    e.printStackTrace();
    return 0;
  }
}

void drawLegendKey(float x, float y) {
  float boxSize = 10;
  float gap = 5;
  textAlign(LEFT, CENTER);
  textSize(10);
  noStroke();

  String[] keys = {"Sleep", "Work", "Exercise", "Hobbies", "Entertainment"};
  for (int i = 0; i < keys.length; i++) {
    float yy = y + i * (boxSize + gap);
    fill(getColor(keys[i]));
    rect(x, yy, boxSize, boxSize, 2);
    fill(0);
    text(keys[i], x + boxSize + 6, yy + boxSize / 2);
  }
}
