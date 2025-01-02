public class DateFormatUtility {
    public class FormattingException extends Exception {
    }

    public static String formatDateTimeToString(DateTime inputDate) {
        String formattedDate = DateTime.ValueOf(inputDate)
            .format('dd MMM yyyy HH:mm');
        return formattedDate;
    }

    public static String formatDateToString(Date inputDate, String dateFormat) {
        return DateTime.newInstance(
                inputDate.year(),
                inputDate.month(),
                inputDate.day()
            )
            .format(dateFormat);
    }

    public static DateTime parseDateTimeFromString(String dateString) {
        if (dateString != null) {
            return (DateTime) JSON.deserialize(
                '"' + dateString + '"',
                DateTime.class
            );
        }
        return null;
    }

    public static Date parseDateFromString(String dateString) {
        if (dateString != null) {
            return (Date) JSON.deserialize('"' + dateString + '"', Date.class);
        }
        return null;
    }

    /**
     * @description Takes in a list of strings and returns a date object. The list should contain the day, month and year in that order.
     *
     * @param dateList - A list of strings containing the day, month and year in that order.
     */
    public static Date parseDateFromString(String dateString, String format) {
        if (format == 'dd.MM.yyyy') {
            List<String> dateList = dateString.split('\\.');

            return Date.newInstance(
                Integer.valueOf(dateList[2]),
                Integer.valueOf(dateList[1]),
                Integer.valueOf(dateList[0])
            );
        }

        return parseDateFromString(dateString);
    }
}
