# APU Medical Center - Reports & Analytics System

## Overview
This comprehensive reports and analytics system provides managers with detailed insights into staff performance, appointment trends, demographics, and revenue analysis. The system includes both a live dashboard with interactive charts and downloadable PDF reports.

## Features

### 📊 Live Dashboard
- **Real-time KPI Cards**: Revenue, appointments, staff count, and average ratings
- **Interactive Charts**: Revenue trends, appointment analytics, staff performance, and demographics
- **Performance Tables**: Top doctors and most booked doctors with detailed metrics
- **Responsive Design**: Works on desktop, tablet, and mobile devices

### 📄 PDF Report Generation
The system generates four types of comprehensive PDF reports:

#### 1. Staff Performance Report
- **Top 5 Rated Doctors**: Rankings with specializations, ratings, and appointment counts
- **Top 5 Counter Staff**: Performance metrics and customer service ratings  
- **Training Needs Identification**: Staff requiring additional training (rating < 6.0)
- **Recommendations**: Actionable insights for staff development

#### 2. Appointment Analytics Report
- **Most Booked Doctors**: Monthly booking statistics with revenue calculations
- **Appointment Status Summary**: Breakdown of pending, confirmed, and completed appointments
- **Weekly Trends Analysis**: Day-of-week patterns and peak booking times
- **Usage Patterns**: Insights into appointment scheduling behaviors

#### 3. Staff Demographics Report
- **Gender Distribution**: Male/female ratios with percentages
- **Role Distribution**: Breakdown by doctors, counter staff, and managers
- **Age Group Analysis**: Distribution across age ranges (20-30, 31-40, 41-50, 51+)
- **Workforce Analytics**: Comprehensive staff composition insights

#### 4. Revenue Analytics Report
- **Total Revenue Summary**: Overall and monthly revenue figures
- **Doctor Revenue Analysis**: Individual doctor performance and earnings
- **Monthly Trends**: 6-month revenue progression with growth indicators
- **Financial KPIs**: Key metrics for business performance evaluation

## Technical Implementation

### Frontend Technologies
- **HTML5/CSS3**: Modern responsive design with CSS Grid and Flexbox
- **JavaScript**: Interactive dashboard with Chart.js for data visualization
- **Bootstrap**: Responsive framework for consistent styling
- **Chart.js**: Professional charts for data presentation
- **AJAX**: Real-time data loading without page refresh

### Backend Technologies
- **Java Servlet**: ReportsServlet.java handles data processing and PDF generation
- **iText PDF Library (5.5.13)**: Professional PDF document creation
- **JSON**: Data exchange format for AJAX communications
- **EJB Integration**: Database access through facade pattern (when available)

### Database Integration
The system integrates with existing APU Medical Center database tables:
- **Doctors**: Performance ratings, specializations, appointment counts
- **Counter Staff**: Service ratings, customer interactions
- **Appointments**: Booking data, status tracking, revenue calculation
- **Payments**: Financial data for revenue analytics
- **Managers**: Administrative access control

## File Structure

```
/manager/
├── reports.jsp              # Main dashboard page
├── manager_homepage.jsp     # Updated with reports link
/css/
├── reports.css              # Dashboard styling
├── manager-homepage.css     # Shared manager styles
/src/java/
├── ReportsServlet.java      # Core servlet for data & PDF generation
/lib/
├── itextpdf-5.5.13.3.jar   # PDF generation library
```

## Setup Instructions

### 1. Library Dependencies
Ensure the following libraries are in your project's lib folder:
```
- itextpdf-5.5.13.3.jar (already included)
- servlet-api.jar (for servlet compilation)
- gson-2.8.5.jar (for JSON handling - optional)
```

### 2. Database Configuration
The servlet expects the following EJB facades to be available:
- `DoctorFacade`
- `CounterStaffFacade`
- `ManagerFacade`
- `AppointmentFacade`
- `PaymentFacade`

### 3. Web.xml Configuration
Add servlet mapping to web.xml:
```xml
<servlet>
    <servlet-name>ReportsServlet</servlet-name>
    <servlet-class>ReportsServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>ReportsServlet</servlet-name>
    <url-pattern>/ReportsServlet</url-pattern>
</servlet-mapping>
```

## Usage Guide

### Accessing the Dashboard
1. Log in as a Manager
2. Navigate to Manager Dashboard
3. Click "Reports & Analytics" card
4. View live dashboard with charts and KPIs

### Downloading Reports
1. In the Reports dashboard, locate "Download Reports" section
2. Choose from four report types:
   - Staff Performance
   - Appointment Analytics  
   - Staff Demographics
   - Revenue Analytics
3. Click on any of the cards to start download
4. Report will be generated and downloaded automatically

### Dashboard Features
- **KPI Cards**: Hover for detailed tooltips
- **Charts**: Interactive with zoom and filter capabilities
- **Time Ranges**: Adjust timeframes using dropdown controls
- **Tables**: Sortable columns for detailed analysis
- **Responsive**: Optimized for all screen sizes

## Customization Options

### Chart Configuration
Modify chart settings in reports.jsp:
```javascript
// Update chart colors
backgroundColor: ['#667eea', '#764ba2', '#f093fb']

// Adjust time ranges
timeframes: ['7days', '30days', '90days', '1year']

// Customize chart types
chartType: 'line' | 'bar' | 'doughnut' | 'horizontalBar'
```

### PDF Styling
Customize PDF appearance in ReportsServlet.java:
```java
// Color scheme
BaseColor primaryBlue = new BaseColor(102, 126, 234);
BaseColor accentGreen = new BaseColor(39, 174, 96);

// Font styles
Font titleFont = new Font(FontFamily.HELVETICA, 24, Font.BOLD);
Font headerFont = new Font(FontFamily.HELVETICA, 16, Font.BOLD);
```

### Data Filtering
Add custom filters to handleDashboardData():
```java
// Date range filtering
Date startDate = parseDate(request.getParameter("startDate"));
Date endDate = parseDate(request.getParameter("endDate"));

// Department filtering
String department = request.getParameter("department");
```

## Security Features
- **Manager Authentication**: Only logged-in managers can access reports
- **Session Validation**: Automatic redirect to login if session expired
- **Data Sanitization**: All user inputs are validated and sanitized
- **Access Control**: Role-based permissions for different report types

## Performance Optimizations
- **AJAX Loading**: Dashboard data loads asynchronously
- **Caching**: Chart data cached for improved response times
- **Lazy Loading**: Charts initialize only when visible
- **PDF Streaming**: Reports stream directly to browser (no server storage)

## Browser Compatibility
- Chrome 60+
- Firefox 55+
- Safari 11+
- Edge 15+
- Mobile browsers (iOS Safari, Chrome Mobile)

## Troubleshooting

### Common Issues

**Charts not displaying:**
- Check Chart.js library is loaded
- Verify AJAX requests are successful
- Ensure data format matches chart expectations

**PDF download fails:**
- Confirm iText library is in classpath
- Check servlet mapping in web.xml
- Verify manager authentication

**Styling issues:**
- Clear browser cache
- Check CSS file paths
- Verify Bootstrap is loaded

### Debug Mode
Enable debug logging in ReportsServlet.java:
```java
private static final boolean DEBUG = true;

if (DEBUG) {
    System.out.println("Debug: " + debugMessage);
}
```

## Future Enhancements
- **Export to Excel**: Additional export format options
- **Email Reports**: Automatic report distribution
- **Custom Date Ranges**: User-defined reporting periods
- **Drill-down Analytics**: Detailed analysis views
- **Real-time Updates**: Live data refresh capabilities
- **Advanced Filters**: Multi-criteria filtering options

## Support
For technical support or feature requests, contact the development team or refer to the project documentation.

---

**Note**: This system is designed to integrate seamlessly with the existing APU Medical Center application architecture. All styling and functionality follows the established design patterns for consistency across the application.
