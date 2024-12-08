use std::{collections::HashSet, fs::File, io::Read};

fn in_bounds((y, x): &(isize, isize), length: isize) -> bool {
    !(*y < 0 || *x < 0 || *y >= length || *x >= length)
}

fn main() {
    // read and parse file
    let mut file = String::new();
    File::open("../../8.txt")
        .unwrap()
        .read_to_string(&mut file)
        .unwrap();
    let length = file.lines().count() as isize;
    let antennae = file
        .lines()
        .enumerate()
        .flat_map(|(line_number, line)| {
            line.chars().enumerate().filter_map(
                move |(character_number, character)| match character {
                    '0'..='9' | 'a'..='z' | 'A'..='Z' => {
                        Some((character, line_number as isize, character_number as isize))
                    }
                    _ => None,
                },
            )
        })
        .collect::<Vec<_>>();

    // calculate anitnodes
    let mut part1_antinodes = HashSet::<(isize, isize)>::new();
    let mut part2_antinodes = HashSet::<(isize, isize)>::new();
    for antenna1 in antennae.iter() {
        for antenna2 in antennae.iter() {
            if antenna1.0 != antenna2.0 {
                continue;
            }
            if antenna1.cmp(antenna2).is_ge() {
                continue;
            }

            let (_, antenna1_y, antenna1_x) = *antenna1;
            let (_, antenna2_y, antenna2_x) = *antenna2;

            // part 1
            let antinode1 = (2 * antenna1_y - antenna2_y, 2 * antenna1_x - antenna2_x);
            let antinode2 = (2 * antenna2_y - antenna1_y, 2 * antenna2_x - antenna1_x);

            if in_bounds(&antinode1, length) {
                part1_antinodes.insert(antinode1);
            }
            if in_bounds(&antinode2, length) {
                part1_antinodes.insert(antinode2);
            }

            // part 2
            let mut antinode1 = (antenna1_y, antenna1_x);
            while in_bounds(&antinode1, length) {
                part2_antinodes.insert(antinode1);
                antinode1 = (
                    antinode1.0 + antenna1_y - antenna2_y,
                    antinode1.1 + antenna1_x - antenna2_x,
                );
            }
            let mut antinode2 = (antenna2_y, antenna2_x);
            while in_bounds(&antinode2, length) {
                part2_antinodes.insert(antinode2);
                antinode2 = (
                    antinode2.0 + antenna2_y - antenna1_y,
                    antinode2.1 + antenna2_x - antenna1_x,
                );
            }
        }
    }

    println!("Part 1: {}", part1_antinodes.len());
    println!("Part 2: {}", part2_antinodes.len());
}
