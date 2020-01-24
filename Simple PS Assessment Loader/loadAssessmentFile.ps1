##Thanks to INSITE for letting me publish this.   This is just a simple base script to use for loading assessments.
##  This is meant to be customized for processing a specific assessment, and tailored to each one's exact layout.
##  You'll see in this sample, that the middle 90% of this code is about converting the CSV file into an object that
##  Can be posted into StudentAssessment.  The top bit is about parsing CSV files.  At the very bottom we call loadAssessmentFile
##  To do the actual work, because I was given a bunch of files, and the only way I knew some of the data was from the filename.
##  It's not very well documented because it was ment to be a one-off, but it works really well for our needs.
##  You'll see spots where it just dumps out a variable, that's just to aid in debugging.
##  Please submit any feedback/suggestions/patches to https://github.com/zackclearlaunch/EdfiBits

#Get Client ID and Secret from theassessmentName Assessment Vendor Type From Operations Cockpit
#Replace Date in API URL based on ODS year you are loading to
$ClientID = "myclientId"
$ClientSecret = "mysecret"


$loginURL = "https://yourapiserver/Api/oauth/authorize?Client_id=$ClientID&Response_type=code"
$tokenURL = "https://yourapiserver/Api/oauth/token"

#this has to guard against empty strings and N/A values, that's why it's this ugly regex.
$emptyRegex = "^(?!.*(N\/A|Undetermined)).+$"

#$auth = Invoke-RestMethod -Method Get -Uri $loginURL
#$body = @{Client_id = $ClientID; Client_secret = $ClientSecret; Code = $auth.code; Grant_type = "authorization_code"}
#$token = Invoke-RestMethod -Uri $tokenURL -Method POST -Body $body

#$auth = Invoke-RestMethod -Method Get -Uri $loginURL
#$body = @{Client_id = $ClientID; Client_secret = $ClientSecret; Code = $auth.code; Grant_type = "authorization_code"}
#$token = Invoke-RestMethod -Uri $tokenURL -Method POST -Body $body
#$data = Invoke-RestMethod -Method GET -Uri "https://yourapiserver/Api/api/v2.0/2020/assessments?identifier=theassessmentName-ELA-3-2019&namespace=http://yourorganization.edu/namespaces/AIR" -Headers @{'Authorization' = "Bearer $($token.access_token)"}
#$data

$auth = Invoke-RestMethod -Method Get -Uri $loginURL
$body = @{Client_id = $ClientID; Client_secret = $ClientSecret; Code = $auth.code; Grant_type = "authorization_code"}
$token = Invoke-RestMethod -Uri $tokenURL -Method POST -Body $body




function loadAssessmentFile($filename, $assessmentPrefix, $gradeLevelDescriptor) {

$csv = Import-Csv -Encoding ASCII $filename
##For testing purposes, select just the first object.  That'll let you see if your mapping is correct.
#$csv = $csv | Select-Object -First 1


function LevelToPLD($id) {
	switch($id) {
		"1" { return "Below Basic" }
		"2" { return "Basic" }
		"3" { return "Proficient" }
		"4" { return "Advanced" }
		default { Write-Error "Failed to find $id in LevelToPLD" }
	}
}

function YesNoToPassFail($id) {
	switch($id) {
		"Yes" { return "Pass" }
		"No" { return "Fail" }
		default { Write-Error "Failed to find $id in YesNoToPassFail" }
	}
}



#Now get the Student Assessment data, and build up the actual student assessment records.

$res = @()
#$csv

$csv | Foreach-Object -Process {

	$elaAssessment = @{
		  assessmentReference= @{
			identifier= $assessmentPrefix + "-ELA";
			namespace= 'http://yourorganization.edu/namespaces/AIR';
		  };
		  studentReference= @{
			studentUniqueId= $_.STN;
		  };
		  administrationDate= "2019-05-01T00:00:00.000Z";
		  identifier= $assessmentPrefix + "-ELA" + '-' +$_.STN;
		  whenAssessedGradeLevelDescriptor= $gradeLevelDescriptor;
		  performanceLevels= @();
		  scoreResults= @();
		  studentObjectiveAssessments= @();
	}
	
	$mathAssessment = @{
		  assessmentReference= @{
			identifier= $assessmentPrefix + "-MA";
			namespace= 'http://yourorganization.edu/namespaces/AIR';
		  };
		  studentReference= @{
			studentUniqueId= $_.STN;
		  };
		  administrationDate= "2019-05-01T00:00:00.000Z";
		  identifier= $assessmentPrefix + "-MA" + '-' +$_.STN;
		  whenAssessedGradeLevelDescriptor= $gradeLevelDescriptor;
		  performanceLevels= @();
		  scoreResults= @();
		  studentObjectiveAssessments= @();
	}
	
	$scienceAssessment = @{
		  assessmentReference= @{
			identifier= $assessmentPrefix + "-SCI";
			namespace= 'http://yourorganization.edu/namespaces/AIR';
		  };
		  studentReference= @{
			studentUniqueId= $_.STN;
		  };
		  administrationDate= "2019-05-01T00:00:00.000Z";
		  identifier= $assessmentPrefix + "-SCI" + '-' +$_.STN;
		  whenAssessedGradeLevelDescriptor= $gradeLevelDescriptor;
		  performanceLevels= @();
		  scoreResults= @();
		  studentObjectiveAssessments= @();
	}
	
	$socialAssessment = @{
		  assessmentReference= @{
			identifier= $assessmentPrefix + "-SOC";
			namespace= 'http://yourorganization.edu/namespaces/AIR';
		  };
		  studentReference= @{
			studentUniqueId= $_.STN;
		  };
		  administrationDate= "2019-05-01T00:00:00.000Z";
		  identifier= $assessmentPrefix + "-SOC" + '-' +$_.STN;
		  whenAssessedGradeLevelDescriptor= $gradeLevelDescriptor;
		  performanceLevels= @();
		  scoreResults= @();
		  studentObjectiveAssessments= @();
	}

	$row = $_;
	##Iterate through the various columns, and add in properties if needed.
	foreach($col in $_.PSobject.Properties) {
		switch($col.Name) {
			"English/Language Arts Scale Score" {
				if($row."English/Language Arts Scale Score" -match $emptyRegex) {
					$elaAssessment.scoreResults += @{
					  assessmentReportingMethodType= "Scale score";
					  resultDatatypeType= "Integer";
					  result= $row."English/Language Arts Scale Score"
					}
				}
			}
			"English/Language Arts Proficiency Level" {
				if($row."English/Language Arts Proficiency Level" -match $emptyRegex) {
					$elaAssessment.scoreResults += @{
						assessmentReportingMethodType= "Proficiency level";
						resultDatatypeType= "Level";
						result= $row."English/Language Arts Proficiency Level";
					}
				}
			}
			"English/Language Arts Reported Lexile? Measure" {
				if($row."English/Language Arts Reported Lexile? Measure" -match $emptyRegex) {
					$elaAssessment.scoreResults += @{
					  assessmentReportingMethodType= "Lexile Measure";
					  resultDatatypeType= "Level";
					  result= $row."English/Language Arts Reported Lexile? Measure"
					}
				}
			}
			"English/Language Arts College and Career Readiness Indicator" {
				if($row."English/Language Arts College and Career Readiness Indicator" -match $emptyRegex) {
					$elaAssessment.performanceLevels += @{
						assessmentReportingMethodType= "Workplace readiness score";
						performanceLevelDescriptor= YesNoToPassFail($row."English/Language Arts College and Career Readiness Indicator");
						performanceLevelMet= $true
					}
				}
			}
			"Key Ideas and Textual Support/Vocabulary Reporting Category Achievement Category" {
				if($row."Key Ideas and Textual Support/Vocabulary Reporting Category Achievement Category" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-KeyIdeasandTextualSupportVocab";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Key Ideas and Textual Support/Vocabulary Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Structural Elements and Organization/Connection of Ideas/Media Literacy Reporting Category Achievement Category" {
				if($row."Structural Elements and Organization/Connection of Ideas/Media Literacy Reporting Category Achievement Category" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-StructuralElementsOrganization";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Structural Elements and Organization/Connection of Ideas/Media Literacy Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Structural Elements and Organization/Synthesis and Connection of Ideas/Media Literacy  Reporting Category Achievement Category" {
				if($row."Structural Elements and Organization/Synthesis and Connection of Ideas/Media Literacy  Reporting Category Achievement Category" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-StructuralElementsOrganization";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Structural Elements and Organization/Synthesis and Connection of Ideas/Media Literacy  Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Writing Reporting Category Achievement Category" {
				if($row."Writing Reporting Category Achievement Category" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-WritingReporting";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Writing Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Informative Organization/Purpose" {
				if($row."Informative Organization/Purpose" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-InformativeOrganization";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Informative Organization/Purpose"
						}
					  );
					}
				}
			}
			"Informative Evidence/Development & Elaboration" {
				if($row."Informative Evidence/Development & Elaboration" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-InformativeEvidence";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Informative Evidence/Development & Elaboration"
						}
					  );
					}
				}
			}
			"Informative Conventions" {
				if($row."Informative Conventions" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-InformativeConventions";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Informative Conventions"
						}
					  );
					}
				}
			}
			"Narrative Organization/Purpose" {
				if($row."Narrative Organization/Purpose" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-NarrativeOrganization";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Narrative Organization/Purpose"
						}
					  );
					}
				}
			}
			"Narrative Evidence/Development & Elaboration" {
				if($row."Narrative Evidence/Development & Elaboration" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-NarrativeEvidence";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Narrative Evidence/Development & Elaboration"
						}
					  );
					}
				}
			}
			"Narrative Conventions" {
				if($row."Narrative Conventions" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-NarrativeConventions";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Narrative Conventions"
						}
					  );
					}
				}
			}
			"Persuasive Organization/Purpose" {
				if($row."Persuasive Organization/Purpose" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-PersuasiveOrganization";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Persuasive Organization/Purpose"
						}
					  );
					}
				}
			}
			"Persuasive Evidence/Development & Elaboration" {
				if($row."Persuasive Evidence/Development & Elaboration" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-PersuasiveEvidence";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Persuasive Evidence/Development & Elaboration"
						}
					  );
					}
				}
			}
			"Persuasive Conventions" {
				if($row."Persuasive Conventions" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-PersuasiveConventions";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Persuasive Conventions"
						}
					  );
					}
				}
			}
			"Argumentative Organization/Purpose" {
				if($row."Argumentative Organization/Purpose" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-PersuasiveOrganization";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Argumentative Organization/Purpose"
						}
					  );
					}
				}
			}
			"Argumentative Evidence/Development & Elaboration" {
				if($row."Argumentative Evidence/Development & Elaboration" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-PersuasiveEvidence";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Argumentative Evidence/Development & Elaboration"
						}
					  );
					}
				}
			}
			"Argumentative Conventions" {
				if($row."Argumentative Conventions" -match $emptyRegex) {
					$elaAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-ELA-PersuasiveConventions";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Argumentative Conventions"
						}
					  );
					}
				}
			}
			
			
			
			
			#MATH!
			
			"Mathematics Scale Score" {
				if($row."Mathematics Scale Score" -match $emptyRegex) {
					$mathAssessment.scoreResults += @{
					  assessmentReportingMethodType= "Scale score";
					  resultDatatypeType= "Integer";
					  result= $row."Mathematics Scale Score"
					}
				}
			}
			"Mathematics Proficiency Level" {
				if($row."Mathematics Proficiency Level" -match $emptyRegex) {
					$mathAssessment.scoreResults += @{
						assessmentReportingMethodType= "Proficiency level";
						resultDatatypeType= "Level";
						result= $row."Mathematics Proficiency Level"
					}
				}
			}
			"Mathematics Reported Quantile? Measure" {
				if($row."Mathematics Reported Quantile? Measure" -match $emptyRegex) {
					$mathAssessment.scoreResults += @{
					  assessmentReportingMethodType= "Quantile Measure";
					  resultDatatypeType= "Level";
					  result= $row."Mathematics Reported Quantile? Measure"
					}
				}
			}
			"Mathematics College and Career Readiness Indicator" {
				if($row."Mathematics College and Career Readiness Indicator" -match $emptyRegex) {
					$mathAssessment.performanceLevels += @{
						assessmentReportingMethodType= "Workplace readiness score";
						performanceLevelDescriptor= YesNoToPassFail($row."Mathematics College and Career Readiness Indicator");
						performanceLevelMet= $true
					}
				}
			}
			
			"Algebraic Thinking and Data Analysis Reporting Category Achievement Category" {
				if($row."Algebraic Thinking and Data Analysis Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-AlgebraicThinking";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Algebraic Thinking and Data Analysis Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Algebraic Thinking Reporting Category Achievement Category" {
				if($row."Algebraic Thinking and Data Analysis Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-AlgebraicThinking";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Algebraic Thinking and Data Analysis Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Algebra and Functions Reporting Category Achievement Category" {
				if($row."Algebra and Functions Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-AlgebraFunctions";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Algebra and Functions Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Computation Reporting Category Achievement Category" {
				if($row."Computation Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-Computation";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Computation Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Geometry and Measurement Reporting Category Achievement Category" {
				if($row."Geometry and Measurement Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-GeometryMeasurement";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Geometry and Measurement Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Geometry and Measurement, Data Analysis, and Statistics Reporting Category Achievement Category" {
				if($row."Geometry and Measurement Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-GeometryMeasurement";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Geometry and Measurement Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Number Sense Reporting Category Achievement Category" {
				if($row."Number Sense Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-NumberSense";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Number Sense Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Number Sense and Computation Reporting Category Achievement Category" {
				if($row."Number Sense and Computation Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-NumberSense";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Number Sense and Computation Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Data Analysis, Statistics, and Probability Reporting Category Achievement Category" {
				if($row."Data Analysis, Statistics, and Probability Reporting Category Achievement Category" -match $emptyRegex) {
					$mathAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-MA-DataAnalysisStatistics";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Data Analysis, Statistics, and Probability Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			
			
			
			
			

			#Science!
			"Science Scale Score" {
				if($row."Science Scale Score" -match $emptyRegex) {
					$scienceAssessment.scoreResults += @{
					  assessmentReportingMethodType= "Scale score";
					  resultDatatypeType= "Integer";
					  result= $row."Science Scale Score"
					}
				}
			}
			"Science Proficiency Level" {
				if($row."Science Proficiency Level" -match $emptyRegex) {
					$scienceAssessment.scoreResults += @{
						assessmentReportingMethodType= "Proficiency level";
						resultDatatypeType= "Level";
						result= $row."Science Proficiency Level"
					}
				}
			}
			"Science College and Career Readiness Indicator" {
				if($row."Science College and Career Readiness Indicator" -match $emptyRegex) {
					$scienceAssessment.performanceLevels += @{
						assessmentReportingMethodType= "Workplace readiness score";
						performanceLevelDescriptor= YesNoToPassFail($row."Science College and Career Readiness Indicator");
						performanceLevelMet= $true
					}
				}
			}
			
			"Questioning and Modeling Reporting Category Achievement Category" {
				if($row."Questioning and Modeling Reporting Category Achievement Category" -match $emptyRegex) {
					$scienceAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-SCI-QuestioningModeling";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Questioning and Modeling Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Investigating Reporting Category Achievement Category" {
				if($row."Investigating Reporting Category Achievement Category" -match $emptyRegex) {
					$scienceAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-SCI-InvestigatingReporting";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Investigating Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Analyzing, Interpreting, and Computational Thinking Reporting Category Achievement Category" {
				if($row."Analyzing, Interpreting, and Computational Thinking Reporting Category Achievement Category" -match $emptyRegex) {
					$scienceAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-SCI-AnalyzingInterpreting";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Analyzing, Interpreting, and Computational Thinking Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Explaining Solutions, Reasoning, and Communicating Reporting Category Achievement Category" {
				if($row."Explaining Solutions, Reasoning, and Communicating Reporting Category Achievement Category" -match $emptyRegex) {
					$scienceAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-SCI-ExplainingSolutions";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Explaining Solutions, Reasoning, and Communicating Reporting Category Achievement Category"
						}
					  );
					}
				}
			}

			
			
			
			#Social Studies!
			"Social Studies Scale Score" {
				if($row."Social Studies Scale Score" -match $emptyRegex) {
					$socialAssessment.scoreResults += @{
					  assessmentReportingMethodType= "Scale score";
					  resultDatatypeType= "Integer";
					  result= $row."Social Studies Scale Score"
					}
				}
			}
			"Social Studies Proficiency Level" {
				if($row."Social Studies Proficiency Level" -match $emptyRegex) {
					$socialAssessment.scoreResults += @{
						assessmentReportingMethodType= "Proficiency level";
						resultDatatypeType= "Level";
						result= $row."Social Studies Proficiency Level"
					}
				}
			}
			"Social Studies College and Career Readiness Indicator" {
				if($row."Social Studies College and Career Readiness Indicator" -match $emptyRegex) {
					$socialAssessment.performanceLevels += @{
						assessmentReportingMethodType= "Workplace readiness score";
						performanceLevelDescriptor= YesNoToPassFail($row."Social Studies College and Career Readiness Indicator");
						performanceLevelMet= $true
					}
				}
			}
			
			"Civics and Government Reporting Category Achievement Category" {
				if($row."Civics and Government Reporting Category Achievement Category" -match $emptyRegex) {
					$socialAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-SOC-Civics";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Civics and Government Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"Geography and Economics Reporting Category Achievement Category" {
				if($row."Geography and Economics Reporting Category Achievement Category" -match $emptyRegex) {
					$socialAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-SOC-GeographyEconomics";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."Geography and Economics Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			"History Reporting Category Achievement Category" {
				if($row."History Reporting Category Achievement Category" -match $emptyRegex) {
					$socialAssessment.studentObjectiveAssessments += @{
					  objectiveAssessmentReference= @{
						identificationCode= $assessmentPrefix + "-SOC-History";
					  };
					  scoreResults= @(@{
						  assessmentReportingMethodType= "Achievement/proficiency level";
						  resultDatatypeType= "Level";
						  result= $row."History Reporting Category Achievement Category"
						}
					  );
					}
				}
			}
			
			
			##These are columns that it's safe to ignore, I don't need to be loading them.
			"Student First Name" {}
			"Student Last Name" {}
			"Student DOB" {}
			"STN" {}
			"Gender" {}
			"Ethnicity" {}
			"Special Education Status" {}
			"Identified English Learner Status" {}
			"Section 504 Status" {}
			"Enrolled Grade" {}
			"Enrolled School" {}
			"Enrolled School ID" {}
			"Enrolled Corporation" {}
			"Enrolled Corporation ID" {}
			##Make sure there aren't any missing columns
			default {
				Write-Output "Failed to find directions for $col"
			}
		}

	}
	
	#insert it if it's not empty.
	if($elaAssessment.performanceLevels.Count -ne 0 -Or $elaAssessment.scoreResults.Count -ne 0 -Or $elaAssessment.studentObjectiveAssessments.Count -ne 0)
	{
		$res += $elaAssessment
	}
	#insert it if it's not empty.
	if($mathAssessment.performanceLevels.Count -ne 0 -Or $mathAssessment.scoreResults.Count -ne 0 -Or $mathAssessment.studentObjectiveAssessments.Count -ne 0)
	{
		$res += $mathAssessment
	}
	#insert it if it's not empty.
	if($scienceAssessment.performanceLevels.Count -ne 0 -Or $scienceAssessment.scoreResults.Count -ne 0 -Or $scienceAssessment.studentObjectiveAssessments.Count -ne 0)
	{
		$res += $scienceAssessment
	}
	#insert it if it's not empty.
	if($socialAssessment.performanceLevels.Count -ne 0 -Or $socialAssessment.scoreResults.Count -ne 0 -Or $socialAssessment.studentObjectiveAssessments.Count -ne 0)
	{
		$res += $socialAssessment
	}
}

#$res




$assessmentIdentifiers = ($res | % { $_.assessmentReference.identifier }) | Sort-Object | Get-Unique
foreach($identifer in $assessmentIdentifiers) {

	$assessment = @{
		identifier = "";
		namespace=  "http://yourorganization.edu/namespaces/AIR";
		categoryDescriptor=  "State assessment";
		title=  "theassessmentName";
		version=  2019;
		academicSubjects=  @()
		assessedGradeLevels=  @(
									@{
										gradeLevelDescriptor= $gradeLevelDescriptor
									}
								)
		identificationCodes=  @()
		performanceLevels=  @(
								  @{
									  assessmentReportingMethodType=  "Achievement/proficiency level";
									  performanceLevelDescriptor=  "Fail"
								  },
								  @{
									  assessmentReportingMethodType=  "Achievement/proficiency level";
									  performanceLevelDescriptor=  "Pass"
								  },
								  @{
									  assessmentReportingMethodType=  "Proficiency level";
									  performanceLevelDescriptor=  "Advanced"
								  },
								  @{
									  assessmentReportingMethodType=  "Proficiency level";
									  performanceLevelDescriptor=  "Basic"
								  },
								  @{
									  assessmentReportingMethodType=  "Proficiency level";
									  performanceLevelDescriptor=  "Below Basic"
								  },
								  @{
									  assessmentReportingMethodType=  "Proficiency level";
									  performanceLevelDescriptor=  "Proficient"
								  },
								  @{
									  assessmentReportingMethodType=  "Workplace readiness score";
									  performanceLevelDescriptor=  "Fail"
								  },
								  @{
									  assessmentReportingMethodType=  "Workplace readiness score";
									  performanceLevelDescriptor=  "Pass"
								  }
							  )
	}
	
	switch($identifer) {
		($assessmentPrefix + "-ELA") {$assessment.identifier = $assessmentPrefix + "-ELA"; $assessment.academicSubjects=@(@{academicSubjectDescriptor=  "English Language Arts"}); $assessment.identificationCodes = @(
									@{
										assessmentIdentificationSystemDescriptor=  "Other";
										identificationCode= $assessmentPrefix + "-ELA"
									}
								)   }
		($assessmentPrefix + "-MA") {$assessment.identifier = $assessmentPrefix + "-MA"; $assessment.academicSubjects=@(@{academicSubjectDescriptor=  "Mathematics"}); $assessment.identificationCodes = @(
									@{
										assessmentIdentificationSystemDescriptor=  "Other";
										identificationCode= $assessmentPrefix + "-MA"
									}
								)    }
		($assessmentPrefix + "-SCI") {$assessment.identifier = $assessmentPrefix + "-SCI"; $assessment.academicSubjects=@(@{academicSubjectDescriptor=  "Science"}); $assessment.identificationCodes = @(
									@{
										assessmentIdentificationSystemDescriptor=  "Other";
										identificationCode= $assessmentPrefix + "-SCI"
									}
								)    }
		($assessmentPrefix + "-SOC") {$assessment.identifier = $assessmentPrefix + "-SOC"; $assessment.academicSubjects=@(@{academicSubjectDescriptor=  "Social Studies"}); $assessment.identificationCodes = @(
									@{
										assessmentIdentificationSystemDescriptor=  "Other";
										identificationCode= $assessmentPrefix + "-SOC"
									}
								)    }
		default { Write-Error "Failed to find assessment $identifer" }
	}



	$assessment = $assessment | ConvertTo-Json -depth 10
	$data = Invoke-RestMethod -Method POST -Uri "https://yourapiserver/Api/api/v2.0/2020/assessments" -Headers @{'Authorization' = "Bearer $($token.access_token)"} -ContentType 'application/json' -Body $assessment


}







$elaAssessmentectiveCodes = ($res | % { $_.studentObjectiveAssessments })  | % { $_.objectiveAssessmentReference.identificationCode } | Sort-Object | Get-Unique

foreach($code in $elaAssessmentectiveCodes) {
	$elaAssessmentective = @{
		assessmentReference = @{
			namespace= 'http://yourorganization.edu/namespaces/AIR';
		}
		description = ""
		identificationCode = $code
		namespace= 'http://yourorganization.edu/namespaces/AIR';
	}
	
	switch($code) {
		($assessmentPrefix + "-ELA-KeyIdeasandTextualSupportVocab") { $elaAssessmentective.description = "Key Ideas and Textual Support/Vocabulary Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-StructuralElementsOrganization") { $elaAssessmentective.description = "Structural Elements, Organization, Connection Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-WritingReporting") { $elaAssessmentective.description = "Writing Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-InformativeOrganization") { $elaAssessmentective.description = "Informative Organization/Purpose"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-InformativeEvidence") { $elaAssessmentective.description = "Informative Evidence/Development & Elaboration"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-InformativeConventions") { $elaAssessmentective.description = "Informative Conventions"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-NarrativeOrganization") { $elaAssessmentective.description = "Narrative Organization/Purpose"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-NarrativeEvidence") { $elaAssessmentective.description = "Narrative Evidence/Development & Elaboration"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-NarrativeConventions") { $elaAssessmentective.description = "Narrative Conventions"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-PersuasiveOrganization") { $elaAssessmentective.description = "Persuasive/Argumentative Organization/Purpose"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-PersuasiveEvidence") { $elaAssessmentective.description = "Persuasive/Argumentative Evidence/Development & Elaboration"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-ELA-PersuasiveConventions") { $elaAssessmentective.description = "Persuasive/Argumentative Conventions"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-ELA' }
		($assessmentPrefix + "-MA-AlgebraicThinking") { $elaAssessmentective.description = "Algebraic Thinking Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-MA' }
		($assessmentPrefix + "-MA-AlgebraFunctions") { $elaAssessmentective.description = "Algebraic Thinking Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-MA' }
		($assessmentPrefix + "-MA-Computation") { $elaAssessmentective.description = "Computation Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-MA' }
		($assessmentPrefix + "-MA-GeometryMeasurement") { $elaAssessmentective.description = "Geometry and Measurement Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-MA' }
		($assessmentPrefix + "-MA-NumberSense") { $elaAssessmentective.description = "Number Sense Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-MA' }
		($assessmentPrefix + "-MA-DataAnalysisStatistics") { $elaAssessmentective.description = "Data Analysis, Statistics, and Probability Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-MA' }
		($assessmentPrefix + "-SCI-QuestioningModeling") { $elaAssessmentective.description = "Questioning and Modeling Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-SCI' }
		($assessmentPrefix + "-SCI-InvestigatingReporting") { $elaAssessmentective.description = "Investigating Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-SCI' }
		($assessmentPrefix + "-SCI-AnalyzingInterpreting") { $elaAssessmentective.description = "Analyzing, Interpreting, and Computational Thinking Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-SCI' }
		($assessmentPrefix + "-SCI-ExplainingSolutions") { $elaAssessmentective.description = "Explaining Solutions, Reasoning, and Communicating Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-SCI' }
		($assessmentPrefix + "-SOC-Civics") { $elaAssessmentective.description = "Civics and Government Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-SOC' }
		($assessmentPrefix + "-SOC-GeographyEconomics") { $elaAssessmentective.description = "Geography and Economics Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-SOC' }
		($assessmentPrefix + "-SOC-History") { $elaAssessmentective.description = "History Reporting Category Achievement Category"; $elaAssessmentective.assessmentReference.identifier = $assessmentPrefix + '-SOC' }
		default { Write-Output "Missing description for code $code." }
	}
	
	$elaAssessmentective = $elaAssessmentective | ConvertTo-Json -depth 10
	
	#$elaAssessmentective
	$data = Invoke-RestMethod -Method POST -Uri "https://yourapiserver/Api/api/v2.0/2020/objectiveAssessments" -Headers @{'Authorization' = "Bearer $($token.access_token)"} -ContentType 'application/json' -Body $elaAssessmentective
	
}


#$data



foreach($re in $res) {
	$re = $re | ConvertTo-Json -depth 10
	#$re
	$data = Invoke-RestMethod -Method POST -Uri "https://yourapiserver/Api/api/v2.0/2020/studentAssessments" -Headers @{'Authorization' = "Bearer $($token.access_token)"} -ContentType 'application/json' -Body $re
	#$data
}





}





loadAssessmentFile '..\theassessmentName\Grade_3_DistrictSpringFiles.csv' 'theassessmentName-3-2019' "Third grade"
loadAssessmentFile '..\theassessmentName\Grade_4_DistrictSpringFiles.csv' 'theassessmentName-4-2019' "Fourth grade"
loadAssessmentFile '..\theassessmentName\Grade_5_DistrictSpringFiles.csv' 'theassessmentName-5-2019' "Fifth grade"
loadAssessmentFile '..\theassessmentName\Grade_6_DistrictSpringFiles.csv' 'theassessmentName-6-2019' "Sixth grade"
loadAssessmentFile '..\theassessmentName\Grade_7_DistrictSpringFiles.csv' 'theassessmentName-7-2019' "Seventh grade"
loadAssessmentFile '..\theassessmentName\Grade_8_DistrictSpringFiles.csv' 'theassessmentName-8-2019' "Eighth grade"







