package model;

import java.sql.Time;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Helper class to group schedules by day and detect continuous schedules across lunch breaks
 */
public class ScheduleHelper {
    
    /**
     * Create a list of consolidated schedules that group morning and afternoon schedules 
     * that span the lunch break
     * 
     * @param schedules The original list of schedules
     * @return A list of ConsolidatedSchedule objects
     */
    public static List<ConsolidatedSchedule> consolidateSchedules(List<Schedule> schedules) {
        Map<String, List<Schedule>> schedulesByDay = new HashMap<>();
        
        // Group schedules by day
        for (Schedule schedule : schedules) {
            String day = schedule.getDayOfWeek();
            if (!schedulesByDay.containsKey(day)) {
                schedulesByDay.put(day, new ArrayList<>());
            }
            schedulesByDay.get(day).add(schedule);
        }
        
        List<ConsolidatedSchedule> result = new ArrayList<>();
        
        // Process each day's schedules
        for (Map.Entry<String, List<Schedule>> entry : schedulesByDay.entrySet()) {
            String day = entry.getKey();
            List<Schedule> daySchedules = entry.getValue();
            
            // Sort schedules by start time
            daySchedules.sort((s1, s2) -> s1.getStartTime().compareTo(s2.getStartTime()));
            
            // Process the schedules for this day
            for (int i = 0; i < daySchedules.size(); i++) {
                Schedule current = daySchedules.get(i);
                
                // Check if this schedule might have a pair after lunch
                if (i + 1 < daySchedules.size()) {
                    Schedule next = daySchedules.get(i + 1);
                    
                    // Check if current ends at 12:00 and next starts at 13:00
                    try {
                        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm:ss");
                        String currentEndStr = current.getEndTime().toString();
                        String nextStartStr = next.getStartTime().toString();
                        
                        // If the current schedule ends at 12:00 and the next starts at 13:00,
                        // and they're on the same day, we can consolidate them
                        if (currentEndStr.startsWith("12:00") && nextStartStr.startsWith("13:00")) {
                            result.add(new ConsolidatedSchedule(current, next));
                            i++; // Skip the next schedule since we've processed it
                            continue;
                        }
                    } catch (Exception e) {
                        // If any error occurs, just add the current schedule normally
                    }
                }
                
                // If no consolidation happened, add the current schedule as is
                result.add(new ConsolidatedSchedule(current));
            }
        }
        
        return result;
    }
    
    /**
     * Class to represent a consolidated schedule (either a single schedule or a pair of schedules
     * that span the lunch break)
     */
    public static class ConsolidatedSchedule {
        private String dayOfWeek;
        private Time displayStartTime;
        private Time displayEndTime;
        private List<Schedule> actualSchedules;
        private boolean spansLunchBreak;
        
        public ConsolidatedSchedule(Schedule schedule) {
            this.dayOfWeek = schedule.getDayOfWeek();
            this.displayStartTime = schedule.getStartTime();
            this.displayEndTime = schedule.getEndTime();
            this.actualSchedules = new ArrayList<>();
            this.actualSchedules.add(schedule);
            this.spansLunchBreak = false;
        }
        
        public ConsolidatedSchedule(Schedule morning, Schedule afternoon) {
            this.dayOfWeek = morning.getDayOfWeek();
            this.displayStartTime = morning.getStartTime();
            this.displayEndTime = afternoon.getEndTime();
            this.actualSchedules = new ArrayList<>();
            this.actualSchedules.add(morning);
            this.actualSchedules.add(afternoon);
            this.spansLunchBreak = true;
        }
        
        public String getDayOfWeek() {
            return dayOfWeek;
        }
        
        public Time getDisplayStartTime() {
            return displayStartTime;
        }
        
        public Time getDisplayEndTime() {
            return displayEndTime;
        }
        
        public List<Schedule> getActualSchedules() {
            return actualSchedules;
        }
        
        public boolean isSpansLunchBreak() {
            return spansLunchBreak;
        }
        
        public Schedule getFirstSchedule() {
            return actualSchedules.get(0);
        }
        
        public String getDisplayText() {
            SimpleDateFormat timeFormat = new SimpleDateFormat("h:mm a");
            String startStr = timeFormat.format(displayStartTime);
            String endStr = timeFormat.format(displayEndTime);
            
            return startStr + " - " + endStr + (spansLunchBreak ? " (includes lunch break)" : "");
        }
    }
}
