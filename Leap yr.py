print ("Find out the leap year")
print ("Enter the year")
year=int (input())
if (int (year%4==0 or year%100==0 or year%400==0)):
    print ("This is a leap year")
else:
    print ("This is not a leap year")