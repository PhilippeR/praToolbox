import pandas as pd
import os
"""
Takes as input all csv files in a directory and sub-directories, 
Extracts the columns you want (e.g. psnr_y, vmaf_hd) 
- to calculate the average for each column. All results are saved in a csv file.
- to make a table of the number of occurrences of each note (int part) in order to graph a histogram. One csv per sub-directory. 

"""
def get_csv_files_from_directories(directories):
    """Récupère tous les fichiers CSV des répertoires et sous-répertoires donnés."""
    csv_files = []
    for directory in directories:
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith('.csv'):
                    csv_files.append(os.path.join(root, file))
    return csv_files

def list_columns_in_csv(file):
    """Affiche les colonnes présentes dans un fichier CSV."""
    try:
        # Lecture du fichier pour prévisualiser les colonnes
        data = pd.read_csv(file, sep=',', decimal='.', encoding='utf-8')
        # print(f"Colonnes trouvées dans '{file}':")
        # print(", ".join(data.columns))
        # print("-" * 40)
    except Exception as e:
        print(f"Erreur lors de la lecture des colonnes dans {file}: {e}")

def calculate_column_means_from_directories(directories, columns, output_file):
    """Calcule les moyennes des colonnes spécifiées pour tous les CSV des répertoires donnés."""
    input_files = get_csv_files_from_directories(directories)
    results = []

    for file in input_files:
        # Liste des colonnes dans le fichier CSV
        list_columns_in_csv(file)
        
        try:
            # Lecture du fichier CSV
            data = pd.read_csv(file, sep=',', decimal='.', encoding='utf-8')
            
            # Nettoyer les colonnes inutiles
            data = data.loc[:, ~data.columns.str.contains('^Unnamed')]

            # Vérification que les colonnes spécifiées existent
            missing_columns = [col for col in columns if col not in data.columns]
            if missing_columns:
                print(f"Colonnes manquantes dans {file}: {missing_columns}")
                continue
            
            # Calcul des moyennes
            means = data[columns].mean()
            results.append([os.path.basename(file)] + means.tolist())
        except Exception as e:
            print(f"Erreur lors du traitement de {file}: {e}")
    
    # Création du dataframe de sortie
    output_columns = ["Source File"] + columns
    output_df = pd.DataFrame(results, columns=output_columns)

    # Sauvegarde dans un fichier CSV
    output_df.to_csv(output_file, index=False)
    print(f"Résultats sauvegardés dans {output_file}")

def count_integer_occurrences(directories, columns, output_directory):
    """Compte le pourcentage des valeurs entières pour les colonnes spécifiées."""
    for directory in directories:
        for root, _, files in os.walk(directory):
            # Identifier les fichiers CSV dans le sous-répertoire
            csv_files = [os.path.join(root, file) for file in files if file.endswith('.csv')]

            if not csv_files:
                continue

            subdir_name = os.path.basename(os.path.normpath(root))

            for column in columns:
                result_data = {"Value": list(range(101))}

                for file in csv_files:
                    try:
                        # Lecture du fichier CSV
                        data = pd.read_csv(file, sep=',', decimal='.', encoding='utf-8')

                        # Nettoyer les colonnes inutiles
                        data = data.loc[:, ~data.columns.str.contains('^Unnamed')]

                        if column in data.columns:
                            # Arrondir les valeurs à leur partie entière
                            rounded_values = data[column].dropna().astype(float).round().astype(int)

                            # Compter les occurrences pour chaque entier
                            total_count = len(rounded_values)
                            counts = rounded_values.value_counts().reindex(range(101), fill_value=0)

                            # Calculer les pourcentages
                            percentages = (counts / total_count * 100).round(2)

                            # Ajouter les résultats au dictionnaire
                            result_key = f"{os.path.basename(file)}"
                            result_data[result_key] = percentages.values
                        else:
                            print(f"Colonne '{column}' non trouvée dans {file}")
                    except Exception as e:
                        print(f"Erreur lors du traitement de {file}: {e}")

                # Création du dataframe de sortie pour cette colonne et ce sous-répertoire
                output_df = pd.DataFrame(result_data)

                # Nom du fichier basé sur le sous-répertoire et la colonne
                output_file = os.path.join(output_directory, f"output_percentages_{subdir_name}_{column}.csv")
                output_df.to_csv(output_file, index=False)
                print(f"Résultats sauvegardés dans {output_file}")


# Exemple d'utilisation
directories = ["d:/temp/StatVMAF/vmaf_result/"]  # Liste des répertoires contenant les fichiers CSV
columns = ["psnr_y"]  # Remplacez par vos colonnes d'intérêt
output_file_means = "d:/temp/StatVMAF/results/output_means.csv"  # Nom du fichier pour les moyennes
output_directory_counts = "d:/temp/StatVMAF/results/"  # Répertoire pour les fichiers des occurrences

calculate_column_means_from_directories(directories, columns, output_file_means)
count_integer_occurrences(directories, columns, output_directory_counts)

