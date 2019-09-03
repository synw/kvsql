# Changelog

## 0.2.1

- Add support for boolean type
- Allow dynamic list and map values
- Fix in case of empty list value
- Add a quiet parameter to selectSync
- Add an example for persistant state

## 0.2.0

- **Major change**: the methods are now type safe and require a type to be declared: ex: `store.insert<int>("key", 3)`
- Add the `hasKey` method
- Add the `count` method
- Update dependencies
- Fix in upsert method
- Fix in database path
- Return null in select if no value is found

## 0.1.0

Initial
