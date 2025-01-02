public class StringFormatUtility {
    public static String stripHtmlTags(String inputString) {
        String formattedString = inputString;
        formattedString = formattedString.stripHtmlTags();

        return formattedString;
    }

    public static String convertNickNameToUserName(String inputNickName) {
        List<User> userName = [
            SELECT Id, Name
            FROM User
            WHERE CommunityNickname = :inputNickName
            LIMIT 1
        ];
        String convertedUserName;

        if (userName.isEmpty()) {
            return null;
        }

        return userName[0].Name;
    }

    public static String getInitials(String inputName) {
        if (inputName != null) {
            String[] names = inputName.split(' ');
            if (names.size() >= 2) {
                String firstNameInitial = names[0].substring(0, 1);
                String lastNameInitial = names[1].substring(0, 1);

                return firstNameInitial + lastNameInitial;
            }
        }
        return '';
    }

    public static String nameConcat(String firstName, String lastName) {
        if (firstName == null && lastName == null) {
            return '';
        }

        if (firstName == null) {
            return lastName;
        }

        if (lastName == null) {
            return firstName;
        }

        return firstName + ' ' + lastName;
    }

    public static String ifNullReplaceWithEmpty(String input) {
        return ifNullReplaceWith(input, '');
    }

    public static String ifNullReplaceWith(String input, String replace) {
        if (String.isBlank(input)) {
            return replace;
        }
        return input;
    }

    /**
     *  @description Method that camelcasializes every word in a string even if it is only one word.
     *  Words must be separated by separator input.
     *
     **/
    public static String camelCaseAllWords(String input, String separator) {
        if (String.isBlank(input)) {
            return input;
        }

        String output = '';
        input = input.toLowerCase();

        List<String> words = input.split(separator);

        Integer count = 0;
        for (String w : words) {
            if (w.contains('-') && w.length() > 1) {
                w = camelCaseAllWords(w, '-');
            }

            String first = w.substring(0, 1);
            String rest = w.substring(1);

            output += first.toUpperCase() + rest;

            if ((count + 1) < words.size()) {
                output += separator;
            }
            count++;
        }

        return output;
    }
}
