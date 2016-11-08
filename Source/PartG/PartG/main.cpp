int plusOne(int number);
int plusOneRef(int &number);


int main(void)
{
	int number = 0;

	number = plusOne(number);

	number = plusOneRef(number);

	return 0;
}


int plusOne(int number)
{
	return number + 1;
}

int plusOneRef(int &number)
{
	return number + 1;
}